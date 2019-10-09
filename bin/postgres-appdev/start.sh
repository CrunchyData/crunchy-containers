#!/bin/bash

# Copyright 2016 - 2019 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

### TODO gonna need this shell script to also fire up pgadmin4 as well


source /opt/cpm/bin/common_lib.sh
enable_debugging

function trap_sigterm() {
    echo_warn "Signal trap triggered, beginning shutdown.." >> $PGDATA/trap.output
    echo_warn "Signal trap triggered, beginning shutdown.."

    # Clean shutdowns begin here (force fast mode in case of PostgreSQL < 9.5)
    echo_info "Cleanly shutting down PostgreSQL in force fast mode.."
    pg_ctl -w -D $PGDATA -m fast stop

    # Unclean shutdowns begin here (if all else fails)
    if [ -f $PGDATA/postmaster.pid ]; then
            kill -SIGINT $(head -1 $PGDATA/postmaster.pid) >> $PGDATA/trap.output
    fi
    if [[ ${ENABLE_SSHD} == "true" ]]; then
        echo_info "killing SSHD.."
        killall sshd
    fi
}

trap 'trap_sigterm' SIGINT SIGTERM

# Only sets path and hostname information (I think)
source /opt/cpm/bin/setenv.sh

### TODO I think this next line is only for running in Kube - we should delete it
source check-for-secrets.sh


env_check_err "PG_PASSWORD"


export PG_MODE="primary"

#These are only needed for replication so we just give them random usernames and passwords
export PG_PRIMARY_USER="user"$(openssl rand -hex 5)
export PG_PRIMARY_PASSWORD="pass"$(openssl rand -hex 5)

# [ -z means if the string is null or spaces only
if [ -z $PG_PRIMARY_PORT  ]
    then
        echo_warn "PG_PRIMARY_PORT is not set, setting port = 5432"
        export PG_PRIMARY_PORT=5432
    else
        export PG_PRIMARY_PORT=$PG_PRIMARY_PORT
    fi

if [ -z $PG_USER  ]
    then
        echo_warn "PG_USER is not set, setting user = rnduser2w3"
        export PG_USER="rnduser2w3"
    else
        export PG_USER=$PG_USER
    fi
if [ -z $PG_DATABASE  ]
    then
        echo_warn "PG_DATABASE is not set, setting database = mydb"
        export PG_DATABASE="mydb"
    else
        export PG_DATABASE=$PG_DATABASE
    fi
if [ -z $PG_ROOT_PASSWORD ]
    then
        echo_warn "PG_ROOT_PASSWORD is not set, setting database = to the password you used for user"
        export PG_ROOT_PASSWORD=$PG_PASSWORD
    else
        export PG_ROOT_PASSWORD=$PG_ROOT_PASSWORD
    fi
export PG_PASSWORD=$PG_PASSWORD

mkdir -p $PGDATA
chmod 0700 $PGDATA


function initdb_logic() {
    echo_info "Starting initdb.."

    cmd="initdb -E UTF8 -D $PGDATA "
    if [[ -v PG_LOCALE ]]; then
        cmd+=" --locale="$PG_LOCALE
    fi

    if [[ -v XLOGDIR ]] && [[ ${XLOGDIR?} == "true" ]]
    then
        echo_info "XLOGDIR enabled.  Setting initdb to use ${PGWAL?}.."
        mkdir ${PGWAL?}

        if [[ -d "${PGWAL?}" ]]
        then
            cmd+=" -X "$PGWAL
        fi
    else
        echo_info "XLOGDIR not found. Using default pg_wal directory.."
    fi

    if [[ ${CHECKSUMS?} == 'true' ]]
    then
        echo_info "Data checksums enabled.  Setting initdb to use data checksums.."
        cmd+=" --data-checksums"
    fi
    cmd+=" > /tmp/initdb.stdout 2> /tmp/initdb.stderr"

    echo_info "Running initdb command: ${cmd?}"
    eval $cmd
    err_check "$?" "Initializing the database (initdb)" \
        "Unable to initialize the database: \n$(cat /tmp/initdb.stderr)"

    echo_info "Overlaying PostgreSQL's default configuration with customized settings.."
    cp /tmp/postgresql.conf $PGDATA

    cp /opt/cpm/conf/pg_hba.conf /tmp
    sed -i "s/PG_PRIMARY_USER/$PG_PRIMARY_USER/g" /tmp/pg_hba.conf
    cp /tmp/pg_hba.conf $PGDATA
}

function fill_conf_file() {
    env_check_info "TEMP_BUFFERS" "Setting TEMP_BUFFERS to ${TEMP_BUFFERS:-8MB}."
    env_check_info "LOG_MIN_DURATION_STATEMENT" "Setting LOG_MIN_DURATION_STATEMENT to ${LOG_MIN_DURATION_STATEMENT:-60000}."
    env_check_info "LOG_STATEMENT" "Setting LOG_STATEMENT to ${LOG_STATEMENT:-none}."
    env_check_info "MAX_CONNECTIONS" "Setting MAX_CONNECTIONS to ${MAX_CONNECTIONS:-100}."
    env_check_info "SHARED_BUFFERS" "Setting SHARED_BUFFERS to ${SHARED_BUFFERS:-128MB}."
    env_check_info "WORK_MEM" "Setting WORK_MEM to ${WORK_MEM:-4MB}."
    env_check_info "MAX_WAL_SENDERS" "Setting MAX_WAL_SENDERS to ${MAX_WAL_SENDERS:-6}."

    cp /opt/cpm/conf/postgresql.conf.template.nopgaudit /tmp/postgresql.conf

    sed -i "s/TEMP_BUFFERS/${TEMP_BUFFERS:-8MB}/g" /tmp/postgresql.conf
    sed -i "s/LOG_MIN_DURATION_STATEMENT/${LOG_MIN_DURATION_STATEMENT:-60000}/g" /tmp/postgresql.conf
    sed -i "s/LOG_STATEMENT/${LOG_STATEMENT:-none}/g" /tmp/postgresql.conf
    sed -i "s/MAX_CONNECTIONS/${MAX_CONNECTIONS:-100}/g" /tmp/postgresql.conf
    sed -i "s/SHARED_BUFFERS/${SHARED_BUFFERS:-128MB}/g" /tmp/postgresql.conf
    sed -i "s/WORK_MEM/${WORK_MEM:-4MB}/g" /tmp/postgresql.conf
    sed -i "s/MAX_WAL_SENDERS/${MAX_WAL_SENDERS:-6}/g" /tmp/postgresql.conf
    sed -i "s/PG_PRIMARY_PORT/${PG_PRIMARY_PORT}/g" /tmp/postgresql.conf
}

function create_pgpass() {
    cd /tmp
cat >> ".pgpass" <<-EOF
*:*:*:*:${PG_PRIMARY_PASSWORD}
EOF
    chmod 0600 .pgpass
}

function waitforpg() {
    export PGPASSFILE=/tmp/.pgpass
    CONNECTED=false
    while true; do
        pg_isready --dbname=$PG_DATABASE --host=$PG_PRIMARY_HOST \
        --port=$PG_PRIMARY_PORT \
        --username=$PG_PRIMARY_USER --timeout=2
        if [ $? -eq 0 ]; then
            echo_info "The database is ready."
            break
        fi
        sleep 2
    done

    while true; do
        psql -h $PG_PRIMARY_HOST -p $PG_PRIMARY_PORT -U $PG_PRIMARY_USER $PG_DATABASE -f /opt/cpm/bin/readiness.sql
        if [ $? -eq 0 ]; then
            echo_info "The database is ready."
            CONNECTED=true
            break
        fi

        echo_info "Attempting pg_isready on primary.."
        sleep 2
    done

}

# Function to create the database if the PGDATA folder is empty, or do nothing if PGDATA
# is not empty.
function initialize_primary() {
    echo_info "Initializing the primary database.."
    if [ ! -f ${PGDATA?}/postgresql.conf ]; then
        ID="$(id)"
        echo_info "PGDATA is empty. ID is ${ID}. Creating the PGDATA directory.."
        mkdir -p ${PGDATA?}


        initdb_logic



        echo "Starting database.." >> /tmp/start-db.log

        echo_info "Temporarily starting database to run setup.sql.."
        pg_ctl -D ${PGDATA?} -o "-c listen_addresses='' ${PG_CTL_OPTS:-}" start \
            2> /tmp/pgctl.stderr
        err_check "$?" "Temporarily Starting PostgreSQL (primary)" \
            "Unable to start PostgreSQL: \n$(cat /tmp/pgctl.stderr)"

        echo_info "Waiting for PostgreSQL to start.."
        while true; do
            pg_isready \
            --host=/tmp \
            --port=${PG_PRIMARY_PORT} \
            --username=${PG_PRIMARY_USER?} \
            --timeout=2
            if [ $? -eq 0 ]; then
                echo_info "The database is ready for setup.sql."
                break
            fi
            sleep 2
        done


        echo_info "Loading setup.sql.." >> /tmp/start-db.log
        cp /opt/cpm/bin/setup.sql /tmp
        if [ -f /pgconf/setup.sql ]; then
            echo_info "Using setup.sql from /pgconf.."
            cp /pgconf/setup.sql /tmp
        else
            echo_info "Using the /opt/cpm/bin/setup.sql"
        fi
        sed -i "s/PG_PRIMARY_USER/$PG_PRIMARY_USER/g" /tmp/setup.sql
        sed -i "s/PG_PRIMARY_PASSWORD/$PG_PRIMARY_PASSWORD/g" /tmp/setup.sql
        sed -i "s/PG_USER/$PG_USER/g" /tmp/setup.sql
        sed -i "s/PG_PASSWORD/$PG_PASSWORD/g" /tmp/setup.sql
        sed -i "s/PG_DATABASE/$PG_DATABASE/g" /tmp/setup.sql
        sed -i "s/PG_ROOT_PASSWORD/$PG_ROOT_PASSWORD/g" /tmp/setup.sql

        # Set PGHOST to use the socket in /tmp. unix_socket_directory is changed
        # to use /tmp instead of /var/run.
        export PGHOST=/tmp
        psql -U postgres -p "${PG_PRIMARY_PORT}" < /tmp/setup.sql

        echo_info "Stopping database after primary initialization.."
        pg_ctl -D $PGDATA --mode=fast stop

    else
        echo_info "PGDATA already contains a database."
    fi
}


# Clean up any old pid file that might have remained
# during a bad shutdown of the container/postgres
echo_info "Cleaning up the old postmaster.pid file.."
if [[ -f $PGDATA/postmaster.pid ]]
then
    rm $PGDATA/postmaster.pid
fi

# The standard PostgreSQL startup sequence:
# export USER_ID=$(id -u)
# cp /opt/cpm/conf/passwd /tmp
# sed -i "s/USERID/$USER_ID/g" /tmp/passwd
# export LD_PRELOAD=libnss_wrapper.so NSS_WRAPPER_PASSWD=/tmp/passwd  NSS_WRAPPER_GROUP=/etc/group
ID="$(id)"
echo_info "User ID is set to ${ID}."

fill_conf_file
initialize_primary

source /opt/cpm/bin/custom-configs.sh

######### Start up PGadmin4
########   source /opt/cpm/bin/start-pgadmin4.sh


# Run pre-start hook if it exists
if [ -f /pgconf/pre-start-hook.sh ]
then
	source /pgconf/pre-start-hook.sh
fi

# Start SSHD if necessary prior to starting PG
source /opt/cpm/bin/sshd.sh

echo_info "Starting PostgreSQL.."
postgres -D $PGDATA &

# Apply enhancement modules
for module in /opt/cpm/bin/modules/*.sh
do
    source ${module?}
done


# Run post start hook if it exists
if [ -f /pgconf/post-start-hook.sh ]
then
	source /pgconf/post-start-hook.sh
fi


# We will wait indefinitely until "docker stop [container_id]"
# When that happens, we route to the "trap_sigterm" function above
wait

echo_info "PostgreSQL is shutting down. Exiting.."