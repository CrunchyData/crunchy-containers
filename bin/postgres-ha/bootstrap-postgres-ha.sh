#!/bin/bash

# Copyright 2019 - 2020 Crunchy Data Solutions, Inc.
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

export PGHOST="/tmp"
export PGPORT="$PGHA_PG_PORT"

source /opt/cpm/bin/common/common_lib.sh
enable_debugging

trap_sigterm() {

    echo_warn "Signal trap triggered, beginning shutdown.." | tee -a "${PATRONI_POSTGRESQL_DATA_DIR}"/trap.output

    killall patroni
    echo_warn "Killed Patroni to gracefully shutdown PG" | tee -a "${PATRONI_POSTGRESQL_DATA_DIR}"/trap.output

    if [[ ${ENABLE_SSHD} == "true" ]]
    then
        echo_info "Killing SSHD.."
        killall sshd
    fi

    while killall -0 patroni; do
        echo_info "Waiting for Patroni to terminate.."
        sleep 1
    done
    echo_info "Patroni shutdown complete"
}

# Starts a background process to wait for cluster initialization, restart the database if configuration updates
# are needed, and indicate cluster readiness
initialization_monitor() {
    echo_info "Starting background process to monitor Patroni initization and restart the database if needed"
    {
        # Wait until the health endpoint for the local primary or replica to return 200 indicating it is running
        status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/health" 2> /dev/null)
        until [[ "${status_code}" == "200" ]]
        do
            sleep 1
            echo "Cluster not yet inititialized, retrying" >> "/tmp/patroni_initialize_check.log"
            status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/health" 2> /dev/null)
        done

        # Enable pgbackrest
        if [[ "${PGHA_PGBACKREST}" == "true" ]]
        then
            source "/opt/cpm/bin/pgbackrest/pgbackrest-post-bootstrap.sh"
        fi

        if [[ "${PGHA_INIT}" == "true" ]]
        then
            echo_info "PGHA_INIT is '${PGHA_INIT}', waiting to initialize as primary"
            # Wait until the master endpoint returns 200 indicating the local node is running as the current primary
            status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/master" 2> /dev/null)
            until [[ "${status_code}" == "200" ]]
            do
                sleep 1
                echo "Not yet running as primary, retrying" >> "/tmp/patroni_initialize_check.log"
                status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/master" 2> /dev/null)
            done

            # Ensure the cluster is no longer in recovery
            until [[ $(psql -At -c "SELECT pg_catalog.pg_is_in_recovery()") == "f" ]]
            do
                echo_info "Detected recovery during cluster init, waiting one second..."
                sleep 1
            done

            # if the bootstrap method is not "initdb", we assume we're running an init job and now
            # proceed with shutting down Patroni and the database
            if [[ "${PGHA_BOOTSTRAP_METHOD}" == "initdb" ]]
            then
                # Apply enhancement modules
                echo_info "Applying enahncement modules"
                for module in /opt/cpm/bin/modules/*.sh
                do
                    echo_info "Applying module ${module}"
                    source "${module}"
                done

                # If there are any tablespaces, create them as a convenience to the user, both
                # the directories and the PostgreSQL objects
                source /opt/cpm/bin/common/pgha-tablespaces.sh
                tablespaces_create_postgresql_objects "${PGHA_USER}"

                # Run audit.sql file if exists
                if [[ -f "/pgconf/audit.sql" ]]
                then
                    echo_info "Running custom audit.sql file"
                    psql < "/pgconf/audit.sql"
                fi
            else
                echo_info "Init job completed, killing Patroni to gracefully shutdown PostgreSQL"
                killall patroni
                killall sshd

                while killall -0 patroni; do
                    echo_info "Waiting for Patroni to terminate following init job..."
                    sleep 1
                done
            fi
        else
            echo_info "PGHA_INIT is '${PGHA_INIT}', skipping post-init process "
        fi

        touch "/crunchyadm/pgha_initialized"  # write file to indicate the cluster is fully initialized
        echo_info "Node ${PATRONI_NAME} fully initialized for cluster ${PATRONI_SCOPE} and is ready for use"
    } &
}

# Waits for the primary node specified to be initialized prior to initializing the replica in order to
# orchestrate primary and replica placement
primary_initialization_monitor() {
    echo_info "Primary host specified, checking if Primary is ready before initializing replica"
    env_check_err "PGHA_PRIMARY_HOST"
    while [[ $(curl --silent "${PGHA_PRIMARY_HOST}:${PGHA_PATRONI_PORT}/master" --stderr - \
        | /opt/cpm/bin/yq r - state 2> /dev/null) != "running" ]]
    do
        echo_info "Primary is not ready, retrying"
        sleep 1
    done
    echo_info "Primary is ready, proceeding with initilization of replica"
}

# Remove the "pause" key from the patroni.dynamic.json if it exists.  This protects against
# Patroni being unable to initialize a restored cluster in the event that the backup utilized for
# the restore was taken while Patroni was paused, resulting in the "pause" key being present in the
# patroni.dynamic.json file contained with the backed up PGDATA directory (if the "pause" key is
# present, normal bootstrapping processes [e.g. leader election] will not occur, and the restored
# database will not be able to initialize).
remove_patroni_pause_key()  {
    if [[ -f "${PATRONI_POSTGRESQL_DATA_DIR}/patroni.dynamic.json" ]]
    then
        echo_info "Now removing \"pause\" key from patroni.dynamic.json configuration file if present"
        sed -i -e "s/\"pause\":\s*true,*\s*//" "${PATRONI_POSTGRESQL_DATA_DIR}/patroni.dynamic.json"
    fi
}

# Checks to see if a PostgreSQL server (v12 or above) is configured for a PITR recovery. This is
# done by checking whether or not a 'recovery.signal' file is present, along with whether or not
# 'recovery_target' settings are present in the 'postgresql.auto.conf' file (as configured by
# pgBackRest during a restore).
is_pg_in_pitr_recovery() {
    [[ -f "${PATRONI_POSTGRESQL_DATA_DIR}/recovery.signal" ]] && has_recovery_target "postgresql.auto.conf"
}

# Checks to see if a PostgreSQL server (v11 or less) is configured for a PITR recovery.  This is
# done by checking whether or not a 'recovery.conf' file is present, along with whether or not
# 'recovery_target' settings are present in the 'recovery.conf' file (as configured by pgBackRest
# during a restore).
is_pg_in_pitr_recovery_legacy() {
    [[ -f "${PATRONI_POSTGRESQL_DATA_DIR}/recovery.conf" ]] && has_recovery_target "recovery.conf"
}

# Checks to see if any "recovery_target" settings are present in the PG config file provided,
# such as a postgresql.conf file (PG 12 and greater) or a recovery.conf file (PG 11 and less)
has_recovery_target() {
    grep -E '^recovery_target' "${PATRONI_POSTGRESQL_DATA_DIR}/$1"
}

# Configure users and groups
source /opt/cpm/bin/common/uid_postgres_no_exec.sh

# Perform cluster pre-initialization (set defaults, load secrets, peform validation, log config details, etc.)
source /opt/cpm/bin/bootstrap/pre-bootstrap.sh

# Enable pgbackrest
if [[ "${PGHA_PGBACKREST}" == "true" ]]
then
    source /opt/cpm/bin/pgbackrest/pgbackrest-pre-bootstrap.sh
fi

# Enable SSHD if needed for a pgBackRest dedicated repository prior to bootstrapping
source /opt/cpm/bin/bootstrap/sshd.sh

if [[ -v PGHA_PRIMARY_HOST ]]
then
    primary_initialization_monitor
fi

# Determine if the database is configured for a PITR.  If so, the database will be started
# manually to ensure the propery recovery target is achieved.  Otherwise, if not perorming
# a PITR, Patroni will handle any recovery and start the database.
if is_pg_in_pitr_recovery || is_pg_in_pitr_recovery_legacy
then
    echo_info "Detected PITR recovery, will start database manually prior to starting Patroni"
    manual_start=true

    echo_info "Removing 'hba_file' and 'ident_file' settings from postgres.conf to ensure a clean start"
    sed -i -E '/^hba_file|^ident_file/d' "${PATRONI_POSTGRESQL_DATA_DIR}/postgresql.conf"
fi

# Start the database manually if needed (e.g. if performing a PITR or converting a non-Patroni
# standalone database).
if [[ "${manual_start}" == "true" ]]
then
    while :
    do
        if ! pgrep --exact postgres &> /dev/null
        then
            # Start PostgreSQL in the background any time it is not running. It will exit if there
            # is an error during recovery, so start it again to retry. Allow only local connections
            # for now. PostgreSQL is restarted later, through Patroni, without these settings.
            pg_ctl start --silent -D "${PATRONI_POSTGRESQL_DATA_DIR}" \
                -o "-c listen_addresses='' -c unix_socket_directories='${PGHOST}'"
        fi

        # Check for ongoing recovery once connected. Since PostgreSQL 10, a hot standby allows
        # connections during recovery:
        # https://postgr.es/m/CABUevEyFk2cbpqqNDVLrgbHPEGLa%2BBV7nu4HAETBL8rK9Df_LA%40mail.gmail.com
        if pg_isready --quiet --username="postgres" &&
            [ "$(psql --quiet --username="postgres" -Atc 'SELECT pg_is_in_recovery()')" = 'f' ]
        then
            break
        else
            echo_info "Database has not reached a consistent state, sleeping..."
            sleep 5
        fi
    done
    echo_info "Reached a consistent state"
fi

# Moinitor for the intialization of the cluster
initialization_monitor

# Remove the pause key from patroni.dynamic.json if it exists
remove_patroni_pause_key

# Bootstrap the cluster
bootstrap_cmd="$@ /tmp/postgres-ha-bootstrap.yaml"
echo_info "Initializing cluster bootstrap with command: '${bootstrap_cmd}'"
# If PID 1 and bootstrapping from scratch via initdb, then run patroni as PID 1.  Otherwise, if
# running as an init job (e.g. to perform a pgbackrest restore) do not run as a PID 1 to ensure
# the container exits with a non-zero exit code in the event the pgbackrest restore fails
if [[ "$$" == 1 && "${PGHA_BOOTSTRAP_METHOD}" == "initdb" ]]
then
    echo_info "Running Patroni as PID 1"
    exec ${bootstrap_cmd}
else
    echo_info "Patroni will not run as PID 1. Creating signal handler"
    trap 'trap_sigterm' SIGINT SIGTERM
    ${bootstrap_cmd}
fi
