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
        # Wait for the local node to enter a "running" state
        while [[ $(curl --silent "127.0.0.1:${PGHA_PATRONI_PORT}/patroni" --stderr - \
            | /opt/cpm/bin/yq r - state 2> /dev/null) != "running" ]]
        do
            sleep 1
            echo "Cluster not yet inititialized, retrying" >> "/tmp/patroni_initialize_check.log"
        done

        # Identify the role of the local node, i.e. primary (master) or replica
        init_role=$(curl --silent "127.0.0.1:${PGHA_PATRONI_PORT}/patroni" --stderr - | \
            /opt/cpm/bin/yq r - role)

        # Wait until the local primary or replica returns 200 indicating it is running
        status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/${init_role}" 2> /dev/null)
        until [[ "${status_code}" == "200" ]]
        do
            sleep 1
            echo "${init_role} not yet inititialized, retrying" >> "/tmp/patroni_initialize_check.log"

            # Refresh the role of the local node, i.e. primary (master) or replica
            init_role=$(curl --silent "127.0.0.1:${PGHA_PATRONI_PORT}/patroni" --stderr - | \
                /opt/cpm/bin/yq r - role)

            status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/${init_role}" 2> /dev/null)
        done

        # Apply custom configuration other than custom 'postgres-ha.yaml', e.g. custom keys and
        # certificates to enable SSL
        source /opt/cpm/bin/bootstrap/ssl-config.sh
        echo_info "SSL config is: ${PGHA_SSL_CONFIG}"

        if [[ "${init_role}" == "master" ]]
        then
            echo_info "Detected that the local node has been initialized as 'master'"
            echo_info "Now executing the post-init process to fully initialize the cluster"
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
                source "/opt/cpm/bin/pgbackrest/pgbackrest-post-bootstrap.sh"
            fi

            # Create the crunchyadm user
            if [[ "${PGHA_CRUNCHYADM}" == "true" ]]
            then
                echo_info "Creating user crunchyadm"
                psql -c "CREATE USER crunchyadm LOGIN;"
            fi

            # If SSL certificates have been configured for the cluster, patch the cluster
            # configuration to enable SSL and then restart the node
            if [[ "${PGHA_SSL_CONFIG}" != "" ]]
            then
                echo_info "Now patching DCS to apply SSL configuration ${PGHA_SSL_CONFIG}"
                curl -s -XPATCH -d \
                    "{\"postgresql\":{\"parameters\":{\"ssl\":\"on\"${PGHA_SSL_CONFIG}}}}" \
                    "127.0.0.1:${PGHA_PATRONI_PORT}/config"
                echo_info "Executing Patroni restart to apply SSL configuration"
                curl -X POST --silent "127.0.0.1:${PGHA_PATRONI_PORT}/restart"
            fi
        else
            echo_info "Detected that the local node has been initialized as 'replica'"
            echo_info "The post-init process is not executed for replicas and will be skipped"
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
        echo "Now removing \"pause\" key from patroni.dynamic.json configuration file if present"
        sed -i -e "s/\"pause\":\s*true,*\s*//" "${PATRONI_POSTGRESQL_DATA_DIR}/patroni.dynamic.json"
    fi
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

# Start the database manually if creating a cluster from an existing database and not intitilizing a new one
if [[ ! -f "/crunchyadm/pgha_initialized" && "${PGHA_INIT}" == "true" && \
    -f "${PATRONI_POSTGRESQL_DATA_DIR}/PG_VERSION" ]]
then
    echo_info "Existing database found in PGDATA directory of initialization node"

    # If the Patroni bootstap configuration file is configured to use a custom PG config file using
    # the custom_config parameter, or if a postgresql.base.conf file is present in the PGDATA
    # directory, then assume those files are the base postgresql.conf parameters for the database
    # in accordance with the Patroni documentation for applying PG configuration to a cluster, and
    # therefore cleans out the contents of the existing postgresql.conf file if it exists (otherwise
    # an empty file will simply be created).  This ensures that the settings from previous Patroni
    # clusters that may no longer be valid (e.g. invalid dir names) do not prevent the DB from
    # starting successfully.  Once Patroni is initialized, the postgresql.conf will be populated
    # with the dynamic configuration defined for the cluster.
    # If a custom or base config file is not found, then the postgresql.conf will remain untouched,
    # and will then become the base configuration is accordance with the Patroni documentation.
    if [[ $(/opt/cpm/bin/yq r "/tmp/postgres-ha-bootstrap.yaml" postgresql.custom_conf) != "null" ]] ||
        [[ -f "${PATRONI_POSTGRESQL_DATA_DIR}/postgresql.base.conf" ]]
    then
        echo_info "Detected existing or custom base configuration for Patroni, cleaning postgresql.conf"
        > "${PATRONI_POSTGRESQL_DATA_DIR}/postgresql.conf"
    fi

    manual_start_pg_ctl_options=""
    # detect if this is a server that needs to entre recovery mode, which is
    # what might happen after an instance is cloned.
    # if this is the case, we will want to have a warm standby
    if [[ -f "${PATRONI_POSTGRESQL_DATA_DIR}/recovery.conf" || -f "${PATRONI_POSTGRESQL_DATA_DIR}/recovery.signal" ]]
    then
      echo_info "Discovered presence of a recovery.conf or recovery.signal file"
      echo_info "Setting hot_standby=\"off\" until PostgreSQL reaches a consistent state"
      manual_start_pg_ctl_options="-c hot_standby=off"
    fi

    echo_info "Starting database manually prior to starting Patroni"
    pg_ctl -D "${PATRONI_POSTGRESQL_DATA_DIR}" -o "-c unix_socket_directories='/tmp'" -o "${manual_start_pg_ctl_options}" start
    echo_info "Database manually started"

    echo_info "Waiting to reach a consistent state"
    until pg_isready --dbname="postgres" --host="${PGHOST}" --port="${PGHA_PG_PORT}" --username="postgres"
    do
        echo_info "Database has not reached a consistent state, sleeping..."
        # sleep to give recovery a chance to complete
        sleep 5
        # if no postgres process is running at this point then assume a failed start and attempt to
        # start again.  Otherwise check once again to see if recovery is complete
        if ! pgrep postgres
        then
            pg_ctl -D "${PATRONI_POSTGRESQL_DATA_DIR}" -o "${manual_start_pg_ctl_options}" start
        fi
    done
    echo_info "Reached a consistent state"

    touch "/crunchyadm/pgha_manual_init"
    echo_info "Manually creating Patroni accounts and proceeding with Patroni initialization"

    if [[ -f "/pgconf/post-existing-init.sql" ]]
    then
        post_existing_init_file="/pgconf/post-existing-init.sql"
    else
        post_existing_init_file="/opt/cpm/bin/sql/post-existing-init.sql"
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

# Remove the pause key from patroni.dynamic.json if it exists
remove_patroni_pause_key

 # Ensure any existing SSL certificates in PGDATA have the proper permissions
chmod -f 0600 "${PATRONI_POSTGRESQL_DATA_DIR}/server.key" "${PATRONI_POSTGRESQL_DATA_DIR}/server.crt" \
    "${PATRONI_POSTGRESQL_DATA_DIR}/ca.crt" "${PATRONI_POSTGRESQL_DATA_DIR}/ca.crl" \
    "${PATRONI_POSTGRESQL_DATA_DIR}/replicator.crt" "${PATRONI_POSTGRESQL_DATA_DIR}/replicator.key" \
    "${PATRONI_POSTGRESQL_DATA_DIR}/replicator.crl"

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
