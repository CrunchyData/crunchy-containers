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

source /opt/cpm/bin/setenv.sh
source check-for-secrets.sh

env_check_err "PG_MODE"

if [ "$PG_MODE" = "replica" ]; then
    env_check_err "PG_PRIMARY_HOST"
fi

env_check_err "PG_PRIMARY_USER"
env_check_err "PG_PRIMARY_PASSWORD"
env_check_err "PG_USER"
env_check_err "PG_PASSWORD"
env_check_err "PG_DATABASE"
env_check_err "PG_ROOT_PASSWORD"
env_check_err "PG_PRIMARY_PORT"

export PG_MODE=$PG_MODE
export PG_PRIMARY_HOST=$PG_PRIMARY_HOST
export PG_REPLICA_HOST=$PG_REPLICA_HOST
export PG_PRIMARY_PORT=$PG_PRIMARY_PORT
export PG_PRIMARY_USER=$PG_PRIMARY_USER
export PG_PRIMARY_PASSWORD=$PG_PRIMARY_PASSWORD
export PG_USER=$PG_USER
export PG_PASSWORD=$PG_PASSWORD
export PG_DATABASE=$PG_DATABASE
export PG_ROOT_PASSWORD=$PG_ROOT_PASSWORD

mkdir -p $PGDATA
chmod 0700 $PGDATA

if [[ -v ARCHIVE_MODE ]]; then
    if [ $ARCHIVE_MODE == "on" ]; then
        mkdir -p $PGWAL
        chmod 0700 $PGWAL
        echo_info "Creating wal directory in ${PGWAL?}.."
    fi
fi

## where pg-wrapper is called
function role_discovery() {
    PATH=$PATH:/opt/cpm/bin
    ordinal=${HOSTNAME##*-}
    echo_info "Ordinal is set to ${ordinal?}."
    if [ $ordinal -eq 0 ]; then
        pgc label --overwrite=true pod $HOSTNAME  name=$PG_PRIMARY_HOST > /tmp/pgc.stdout 2> /tmp/pgc.stderr
        err_check "$?" "Statefulset Role Discovery (primary)" \
            "Unable to set mode on pod, label command failed: \n$(cat /tmp/pgc.stderr)"
        export PG_MODE=primary
    else
        pgc label --overwrite=true pod $HOSTNAME  name=$PG_REPLICA_HOST > /tmp/pgc.stdout 2> /tmp/pgc.stderr
        err_check "$?" "Statefulset Role Discovery (replica)" \
            "Unable to set mode on pod, label command failed: \n$(cat /tmp/pgc.stderr)"
        export PG_MODE=replica
    fi

    echo_info "Setting PG_MODE to ${PG_MODE?}"
}

function initdb_logic() {
    echo_info "Starting initdb.."

    #	tar xzf /opt/cpm/conf/data.tar.gz --directory=$PGDATA
    cmd="initdb -D $PGDATA "
    if [[ -v PG_LOCALE ]]; then
        cmd+=" --locale="$PG_LOCALE
    else
        cmd+=" --locale=en_US.utf8"
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

    cp /opt/cpm/conf/postgresql.conf.template /tmp/postgresql.conf

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

function initialize_replica() {
    echo_info "Initializing the replica."
    rm -rf $PGDATA/*
    chmod 0700 $PGDATA

    echo_info "Waiting to allow the primary database time to successfully start before performing the initial backup.."
    waitforpg

    pg_basebackup -X fetch --no-password --pgdata $PGDATA --host=$PG_PRIMARY_HOST \
        --port=$PG_PRIMARY_PORT -U $PG_PRIMARY_USER > /tmp/pgbasebackup.stdout 2> /tmp/pgbasebackup.stderr
    err_check "$?" "Initialize Replica" "Could not run pg_basebackup: \n$(cat /tmp/pgbasebackup.stderr)"

    # PostgreSQL recovery configuration.
    if [[ -v SYNC_REPLICA ]]; then
        echo_info "SYNC_REPLICA environment variable is set."
        APPLICATION_NAME=$SYNC_REPLICA
    else
        APPLICATION_NAME=$HOSTNAME
        echo_info "SYNC_REPLICA environment variable is not set."
    fi
    echo_info "${APPLICATION_NAME} is the APPLICATION_NAME being used."

    cp /opt/cpm/conf/pgrepl-recovery.conf /tmp
    sed -i "s/PG_PRIMARY_USER/$PG_PRIMARY_USER/g" /tmp/pgrepl-recovery.conf
    sed -i "s/PG_PRIMARY_HOST/$PG_PRIMARY_HOST/g" /tmp/pgrepl-recovery.conf
    sed -i "s/PG_PRIMARY_PORT/$PG_PRIMARY_PORT/g" /tmp/pgrepl-recovery.conf
    sed -i "s/APPLICATION_NAME/$APPLICATION_NAME/g" /tmp/pgrepl-recovery.conf
    cp /tmp/pgrepl-recovery.conf $PGDATA/recovery.conf
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
        if [ -f /pgconf/audit.sql ]; then
            echo_info "Using pgaudit_analyze audit.sql from /pgconf.."
            psql -U postgres < /pgconf/audit.sql
        fi

        echo_info "Stopping database after primary initialization.."
        pg_ctl -D $PGDATA --mode=fast stop

        if [[ -v SYNC_REPLICA ]]; then
            echo "Synchronous_standby_names = '"$SYNC_REPLICA"'" >> $PGDATA/postgresql.conf
        fi
    else
        echo_info "PGDATA already contains a database."
    fi
}

configure_archiving() {
    printf "\n# Archive Configuration:\n" >> /"${PGDATA?}"/postgresql.conf

    export ARCHIVE_MODE=${ARCHIVE_MODE:-off}
    export ARCHIVE_TIMEOUT=${ARCHIVE_TIMEOUT:-0}

    if [[ "${PGBACKREST}" == "true" ]]
    then
        export ARCHIVE_MODE=on
        echo_info "Setting pgbackrest archive command.."
        if [[ "${BACKREST_LOCAL_AND_S3_STORAGE}" == "true" ]]
        then
            cat /opt/cpm/conf/backrest-archive-command-local-and-s3 >> /"${PGDATA?}"/postgresql.conf
        else
            cat /opt/cpm/conf/backrest-archive-command >> /"${PGDATA?}"/postgresql.conf
        fi
    elif [[ "${ARCHIVE_MODE}" == "on" ]] && [[ ! "${PGBACKREST}" == "true" ]]
    then
        echo_info "Setting standard archive command.."
        cat /opt/cpm/conf/archive-command >> /"${PGDATA?}"/postgresql.conf
    fi

    echo_info "Setting ARCHIVE_MODE to ${ARCHIVE_MODE?}."
    echo "archive_mode = ${ARCHIVE_MODE?}" >> "${PGDATA?}"/postgresql.conf

    echo_info "Setting ARCHIVE_TIMEOUT to ${ARCHIVE_TIMEOUT?}."
    echo "archive_timeout = ${ARCHIVE_TIMEOUT?}" >> "${PGDATA?}"/postgresql.conf
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

# For Kube Statefulset support.
case "$PG_MODE" in
    "set")
    role_discovery
    ;;
esac

fill_conf_file

case "$PG_MODE" in
    "replica"|"slave")
    echo_info "Working on replica.."
    create_pgpass
    export PGPASSFILE=/tmp/.pgpass
    if [ ! -f $PGDATA/postgresql.conf ]; then
        initialize_replica
    fi
    ;;
    "primary"|"master")
    echo_info "Working on primary.."
    initialize_primary
    ;;
    *)
    echo_err "PG_MODE is not an accepted value. Check that the PG_MODE environment variable is set to one of the two valid values (primary, replica)."
    ;;
esac

# Configure pgbackrest if enabled
if [[ ${PGBACKREST} == "true" ]]
then
    echo_info "pgBackRest: Enabling pgbackrest.."
    source /opt/cpm/bin/pgbackrest.sh
fi

configure_archiving

source /opt/cpm/bin/custom-configs.sh

# Run pre-start hook if it exists
if [ -f /pgconf/pre-start-hook.sh ]
then
	source /pgconf/pre-start-hook.sh
fi

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
