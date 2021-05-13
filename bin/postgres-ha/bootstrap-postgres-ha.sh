#!/bin/bash

# Copyright 2019 - 2021 Crunchy Data Solutions, Inc.
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

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"
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
            source "${CRUNCHY_DIR}/bin/postgres-ha/pgbackrest/pgbackrest-post-bootstrap.sh"
        fi

        if [[ "${PGHA_INIT}" == "true" ]]
        then

            if [[ "${PGHA_STANDBY}" != "true" ]]
            then
                primary_endpoint="master"
            else
                primary_endpoint="standby_leader"
            fi

            echo_info "PGHA_INIT is '${PGHA_INIT}', waiting to initialize as primary"
            # Wait until the master endpoint returns 200 indicating the local node is running as the current primary
            status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/${primary_endpoint}" 2> /dev/null)
            until [[ "${status_code}" == "200" ]]
            do
                sleep 1
                echo "Not yet running as primary, retrying" >> "/tmp/patroni_initialize_check.log"
                status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/${primary_endpoint}" 2> /dev/null)
            done
        fi

        # Patroni's bootstrap succeeded. Clear the initialization marker from
        # the volume.
        if [[ "${PGHA_INIT}" == "true" && -f "${PATRONI_POSTGRESQL_DATA_DIR}.initializing" ]]
        then
            rm "${PATRONI_POSTGRESQL_DATA_DIR}.initializing"
        fi

        # The following logic only applies to bootstrapping and initializing clusters that are
        # not standby clusters.  Specifically, this logic expects the database to exit recovery
        # and become writable.
        if [[ "${PGHA_INIT}" == "true" && "${PGHA_STANDBY}" != "true" ]]
        then
            # Ensure the cluster is no longer in recovery
            until [[ $(psql -At -c "SELECT pg_catalog.pg_is_in_recovery()") == "f" ]]
            do
                echo_info "Detected recovery during cluster init, waiting one second..."
                sleep 1
            done

            # if the bootstrap method is not "initdb", we assume we're running an init job and now
            # proceed with shutting down Patroni and the database
            if [[ "${PGHA_BOOTSTRAP_METHOD}" != "pgbackrest_init" ]]
            then
                # Apply enhancement modules
                echo_info "Applying enahncement modules"
                for module in "${CRUNCHY_DIR}"/bin/modules/*.sh
                do
                    echo_info "Applying module ${module}"
                    source "${module}"
                done

                # If there are any tablespaces, create them as a convenience to the user, both
                # the directories and the PostgreSQL objects
                source "${CRUNCHY_DIR}/bin/postgres-ha/common/pgha-tablespaces.sh"
                tablespaces_create_postgresql_objects "${PGHA_USER}"

                # Run audit.sql file if exists
                if [[ -f "/pgconf/audit.sql" ]]
                then
                    echo_info "Running custom audit.sql file"
                    psql < "/pgconf/audit.sql"
                fi
            else
                echo_info "Init job completed, shutting down the cluster and removing from the DCS"

                # pause Patroni, stop the database, and then remove the cluster from the DCS
                patronictl pause
                patronictl reload "${PATRONI_SCOPE}" --force &> /dev/null
                pg_ctl stop -m fast -D "${PATRONI_POSTGRESQL_DATA_DIR}"
                printf '%s\nYes I am aware\n%s\n' "${PATRONI_SCOPE}" "${PATRONI_NAME}" | patronictl remove "${PATRONI_SCOPE}" &> /dev/null
                err_check "$?" "Remove from DCS" "Unable to remove cluster from the DCS following init job"
                echo_info "Successfully removed cluster from the DCS"

                # now kill patroni and sshd
                killall patroni
                killall sshd

                while killall -0 patroni; do
                    echo_info "Waiting for Patroni to terminate following init job..."
                    sleep 1
                done
            fi
        fi

        touch "/tmp/pgha_initialized"  # write file to indicate the cluster is fully initialized
        echo_info "Node ${PATRONI_NAME} fully initialized for cluster ${PATRONI_SCOPE} and is ready for use"
    } &
}

# Waits for the primary node specified to be initialized prior to initializing the replica in order to
# orchestrate primary and replica placement
primary_initialization_monitor() {
    echo_info "Primary host specified, checking if Primary is ready before initializing replica"
    env_check_err "PGHA_PRIMARY_HOST"
    while [[ $(curl --silent "${PGHA_PRIMARY_HOST}:${PGHA_PATRONI_PORT}/master" --stderr - \
        | "${CRUNCHY_DIR}/bin/yq" r - state 2> /dev/null) != "running" ]]
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

# If there was a prior attempt to initialize, repeatedly log some advice.
# Otherwise, mark the volume to indicate initialization will soon take place.
# This is outside of PATRONI_POSTGRESQL_DATA_DIR so that Patroni does not move
# it when bootstrap fails.
if [[ "${PGHA_INIT}" == "true" ]]
then
    if [[ -f "${PATRONI_POSTGRESQL_DATA_DIR}.initializing" ]]
    then
        while
            echo_warn "Detected an earlier failed attempt to initialize"
            echo_info "Correct the issue, remove '${PATRONI_POSTGRESQL_DATA_DIR}.initializing', and try again"
            echo_info "Your data might be in: $(echo ${PATRONI_POSTGRESQL_DATA_DIR}_*)"
        do
            sleep 10 & wait $!
        done
    fi

    date --iso-8601=ns --utc > "${PATRONI_POSTGRESQL_DATA_DIR}.initializing"
fi

# Configure users and groups
source "${CRUNCHY_DIR}/bin/uid_postgres_no_exec.sh"

# remove the "initialized" file and initialize logs if they already exist (e.g. after a restart)
rm -f "/tmp/pgha_initialized" "/tmp/patroni_initialize_check.log"

# Perform cluster pre-initialization (set defaults, load secrets, peform validation, log config details, etc.)
source "${CRUNCHY_DIR}/bin/postgres-ha/bootstrap/pre-bootstrap.sh"

# Enable pgbackrest
if [[ "${PGHA_PGBACKREST}" == "true" ]]
then
    source "${CRUNCHY_DIR}/bin/postgres-ha/pgbackrest/pgbackrest-pre-bootstrap.sh"
fi

# Enable SSHD if needed for a pgBackRest dedicated repository prior to bootstrapping
source "${CRUNCHY_DIR}/bin/postgres-ha/bootstrap/sshd.sh"

if [[ -v PGHA_PRIMARY_HOST ]]
then
    primary_initialization_monitor
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
if [[ "$$" == 1 && "${PGHA_BOOTSTRAP_METHOD}" != "pgbackrest_init" ]]
then
    echo_info "Running Patroni as PID 1"
    exec ${bootstrap_cmd}
else
    echo_info "Patroni will not run as PID 1. Creating signal handler"
    trap 'trap_sigterm' SIGINT SIGTERM
    ${bootstrap_cmd}
fi
