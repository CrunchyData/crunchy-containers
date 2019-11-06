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

export PGHOST="/tmp"

source /opt/cpm/bin/common_lib.sh
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
        while [[ $(curl --silent "127.0.0.1:${PGHA_PATRONI_PORT}/master" --stderr - \
            | /opt/cpm/bin/yq r - state 2> /dev/null) != "running" ]]
        do
            sleep 1
            echo "Cluster not yet inititialized, retrying" >> "/tmp/patroni_initialize_check.log"
        done
        echo_info "Detected that Patroni has initilized the cluster"
        if [[ -f "/crunchyadm/pgha_manual_init" ]]
        then
            echo_info "Executing Patroni restart to restart database and update configuration"
            curl -X POST --silent "127.0.0.1:${PGHA_PATRONI_PORT}/restart"
            test_server "postgres" "${PGHOST}" "${PGHA_PG_PORT}" "postgres"
            echo_info "The database has been restarted"
        else
            echo "Pending restart not detected, will not restart" >> "/tmp/patroni_initialize_check.log"
        fi
        
        # Enable pgbackrest
        if [[ "${PGHA_PGBACKREST}" == "true" ]]
        then
            source "/opt/cpm/bin/pgbackrest-post-bootstrap.sh"
        fi

        # Create the crunchyadm user
        if [[ "${PGHA_CRUNCHYADM}" == "true" ]]
        then
            echo_info "Creating user crunchyadm"
            psql -c "CREATE USER crunchyadm LOGIN;"
        fi
        
        touch "/crunchyadm/pgha_initialized"  # write file to indicate the cluster is fully initialized
        echo_info "PostgreSQL Database Cluster ${PATRONI_SCOPE} fully initialized and ready for use"
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

# Configure users and groups
source /opt/cpm/bin/uid_postgres_no_exec.sh

# Perform cluster pre-initialization (set defaults, load secrets, peform validation, log config details, etc.)
source /opt/cpm/bin/pre-bootstrap.sh

# Enable pgbackrest
if [[ "${PGHA_PGBACKREST}" == "true" ]]
then
    source /opt/cpm/bin/pgbackrest-pre-bootstrap.sh
fi

# Enable SSHD if needed for a pgBackRest dedicated repository prior to bootstrapping
source /opt/cpm/bin/sshd.sh

if [[ -v PGHA_PRIMARY_HOST ]]
then
    primary_initialization_monitor
fi

# Start the database manually if creating a cluster from an existing database and not intitilizing a new one
if [[ ! -f "/crunchyadm/pgha_initialized" && "${PGHA_INIT}" == "true" && \
    -f "${PATRONI_POSTGRESQL_DATA_DIR}/PG_VERSION" ]]
then
    echo_info "Existing database found in PGDATA directory of initialization node"
    
    echo_info "Starting database manually prior to starting Patroni"
    pg_ctl -D "${PATRONI_POSTGRESQL_DATA_DIR}" start
    touch "/crunchyadm/pgha_manual_init"
    
    test_server "postgres" "${PGHOST}" "${PGHA_PG_PORT}" "postgres"
    echo_info "Database manually started"
    echo_info "Manually creating Patroni accounts and proceeding with Patroni initialization"
    
    if [[ -f "/pgconf/post-existing-init.sql" ]]
    then
        post_existing_init_file="/pgconf/post-existing-init.sql"
    else
        post_existing_init_file="/opt/cpm/bin/post-existing-init.sql"
    fi
    sed -e "s/\${PATRONI_SUPERUSER_USERNAME}/${PATRONI_SUPERUSER_USERNAME}/" \
        -e "s/\${PATRONI_SUPERUSER_PASSWORD}/${PATRONI_SUPERUSER_PASSWORD}/" \
        -e "s/\${PATRONI_REPLICATION_USERNAME}/${PATRONI_REPLICATION_USERNAME}/" \
        -e "s/\${PATRONI_REPLICATION_PASSWORD}/${PATRONI_REPLICATION_PASSWORD}/" \
        ${post_existing_init_file} | \
        psql -f -
fi

# Moinitor for the intialization of the cluster 
initialization_monitor

# Bootstrap the cluster
bootstrap_cmd="$@ /tmp/postgres-ha-bootstrap.yaml"
echo_info "Initializing cluster bootstrap with command: '${bootstrap_cmd}'"
if [[ "$$" == 1 ]]
then
    echo_info "Running Patroni as PID 1"
    exec ${bootstrap_cmd}
else
    echo_info "Patroni will not run as PID 1. Creating signal handler"
    trap 'trap_sigterm' SIGINT SIGTERM
    ${bootstrap_cmd}
fi
