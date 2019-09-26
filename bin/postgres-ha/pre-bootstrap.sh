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

set_default_pgha_env()  {

    if [[ ! -v PGHA_PATRONI_PORT ]]
    then
        export PGHA_PATRONI_PORT="8009"
        default_pgha_env_vars+=("PGHA_PATRONI_PORT=${PGHA_PATRONI_PORT}")
    fi

    if [[ ! -v PGHA_PG_PORT ]]
    then
        export PGHA_PG_PORT="5432"
        default_pgha_env_vars+=("PGHA_PG_PORT=${PGHA_PG_PORT}")
    fi

    if [[ ! -v PGHA_DATABASE ]]
    then
        export PGHA_DATABASE="userdb"
        default_pgha_env_vars+=("PGHA_DATABASE=${PGHA_DATABASE}")
    fi

    if [[ ! ${#default_pgha_env_vars[@]} -eq 0 ]]
    then
        echo_info "Defaults have been set for the following postgres-ha env vars:"
        echo_info "[${default_pgha_env_vars[*]}]"
    fi
}

set_default_patroni_env() {
    
    host_ip=$(hostname -i)

    if [[ ! -v PATRONI_NAME ]]
    then
        export PATRONI_NAME="${HOSTNAME}"
        default_patroni_env_vars+=("PATRONI_NAME=${PATRONI_NAME}")
    fi

    if [[ ! -v PATRONI_SCOPE ]]
    then
        export PATRONI_SCOPE="example-cluster"
        default_patroni_env_vars+=("PATRONI_SCOPE=${PATRONI_SCOPE}")
    fi

    if [[ ! -v PATRONI_RESTAPI_LISTEN ]]
    then
        export PATRONI_RESTAPI_LISTEN="0.0.0.0:${PGHA_PATRONI_PORT}"
        default_patroni_env_vars+=("PATRONI_RESTAPI_LISTEN=${PATRONI_RESTAPI_LISTEN}")
    fi

    if [[ ! -v PATRONI_RESTAPI_CONNECT_ADDRESS ]]
    then
        export PATRONI_RESTAPI_CONNECT_ADDRESS="${host_ip}:${PGHA_PATRONI_PORT}"
        default_patroni_env_vars+=("PATRONI_RESTAPI_CONNECT_ADDRESS=${PATRONI_RESTAPI_CONNECT_ADDRESS}")
    fi

    if [[ ! -v PATRONI_POSTGRESQL_LISTEN ]]
    then
        export PATRONI_POSTGRESQL_LISTEN="0.0.0.0:${PGHA_PG_PORT}"
        default_patroni_env_vars+=("PATRONI_POSTGRESQL_LISTEN=${PATRONI_POSTGRESQL_LISTEN}")
    fi

    if [[ ! -v PATRONI_POSTGRESQL_CONNECT_ADDRESS ]]
    then
        export PATRONI_POSTGRESQL_CONNECT_ADDRESS="${host_ip}:${PGHA_PG_PORT}"
        default_patroni_env_vars+=("PATRONI_POSTGRESQL_CONNECT_ADDRESS=${PATRONI_POSTGRESQL_CONNECT_ADDRESS}")
    fi

    if [[ ! -v PATRONI_POSTGRESQL_DATA_DIR ]]
    then
        export PATRONI_POSTGRESQL_DATA_DIR="/pgdata/${HOSTNAME}"
        default_patroni_env_vars+=("PATRONI_POSTGRESQL_DATA_DIR=${PATRONI_POSTGRESQL_DATA_DIR}")
    fi

    if [[ ! ${#default_patroni_env_vars[@]} -eq 0 ]]
    then
        echo_info "Defaults have been set for the following Patroni env vars:"
        echo_info "[${default_patroni_env_vars[*]}]"
    fi
}

# Set the PG user credentials for Patroni & post-bootstrap using the file system (e.g. Kube secrets)
set_pg_user_credentials() {
    echo_info "Setting postgres-ha configuration for database user credentials"
    
    if [[ -d "/opt/cpm/conf/pguser" ]]
    then
	    echo_info "Setting 'pguser' credentials using file system"

	    PGHA_USER=$(cat /opt/cpm/conf/pguser/username)
	    export PGHA_USER

        PGHA_USER_PASSWORD=$(cat /opt/cpm/conf/pguser/password)
        export PGHA_USER_PASSWORD
    else
        env_check_err "PGHA_USER"
        env_check_err "PGHA_USER_PASSWORD"
    fi

    if [[ -d "/opt/cpm/conf/pgsuper" ]]
    then
        echo_info "Setting 'superuser' credentials using file system"
        
        PATRONI_SUPERUSER_USERNAME=$(cat /opt/cpm/conf/pgsuper/username)
        export PATRONI_SUPERUSER_USERNAME
        
        PATRONI_SUPERUSER_PASSWORD=$(cat /opt/cpm/conf/pgsuper/password)
        export PATRONI_SUPERUSER_PASSWORD
    else
        env_check_err "PATRONI_SUPERUSER_USERNAME"
        env_check_err "PATRONI_SUPERUSER_PASSWORD"
    fi


    if [[ -d "/opt/cpm/conf/pgreplicator" ]]
    then
        echo_info "Setting 'replicator' credentials using file system"
        
        PATRONI_REPLICATION_USERNAME=$(cat /opt/cpm/conf/pgreplicator/username)
        export PATRONI_REPLICATION_USERNAME
        
        PATRONI_REPLICATION_PASSWORD=$(cat /opt/cpm/conf/pgreplicator/password)
        export PATRONI_REPLICATION_PASSWORD
    else
        env_check_err "PATRONI_REPLICATION_USERNAME"
        env_check_err "PATRONI_REPLICATION_PASSWORD"
    fi

    export PATRONI_monitor_PASSWORD=""
    export PATRONI_monitor_OPTIONS="login"
}

# Build the Patroni bootstrap configuration file
build_bootstrap_config_file() {
    
    bootstrap_file="/tmp/postgres-ha-bootstrap.yaml"
    echo "---" >> "${bootstrap_file}"

    if [[ -f "/pgconf/postgresql.conf" ]]
    then
        echo_info "Setting custom 'postgresql.conf' as base config using 'custom_conf'"
        /opt/cpm/bin/yq m -i -x "${bootstrap_file}" "/opt/cpm/conf/postgres-ha-custom-pgconf.yaml"
    fi

    if [[ "${PGHA_BASE_BOOTSTRAP_CONFIG:-true}" == "true" ]]
    then
        echo_info "Applying base bootstrap config to postgres-ha configuration"
        /opt/cpm/bin/yq m -i -x "${bootstrap_file}" "/opt/cpm/conf/postgres-ha-bootstrap.yaml"
    fi
    
    if [[ "${PGHA_BASE_PG_CONFIG:-true}" == "true" ]]
    then
        cp "/opt/cpm/conf/postgres-ha-pgconf.yaml" "/tmp"
        sed -i "s/PGHA_USER/$PGHA_USER/g" "/tmp/postgres-ha-pgconf.yaml"
        sed -i "s/PATRONI_REPLICATION_USERNAME/$PATRONI_REPLICATION_USERNAME/g" "/tmp/postgres-ha-pgconf.yaml"
        echo_info "Applying base postgres config to postgres-ha configuration"
        /opt/cpm/bin/yq m -i -x "${bootstrap_file}" "/tmp/postgres-ha-pgconf.yaml"
    fi

    if [[ -v "${PGHA_WAL_DIR}" ]]
    then
        cp "/opt/cpm/conf/postgres-ha-wal.yaml" "/tmp"
        sed -i "s/PGHA_WAL_DIR/$PGHA_WAL_DIR/g" "/tmp/postgres-ha-wal.yaml"
        echo_info "Applying custom WAL dir tos postgres-ha configuration"
        /opt/cpm/bin/yq m -i -x "${bootstrap_file}" "/tmp/postgres-ha-wal.yaml"
    fi

    if [[ "${PGHA_PGBACKREST:-true}" == "true" ]]
    then
        echo_info "Applying pgbackrest config to postgres-ha configuration"
        if [[ "${PGHA_PGBACKREST_LOCAL_S3_STORAGE:false}" == "true" ]]
        then
            /opt/cpm/bin/yq m -i -x "${bootstrap_file}" "/opt/cpm/conf/postgres-ha-pgbackrest-local-s3.yaml"
        else
            /opt/cpm/bin/yq m -i -x "${bootstrap_file}" "/opt/cpm/conf/postgres-ha-pgbackrest.yaml"
        fi
    fi

    if [[ -f "/pgconf/postgres-ha.yaml" ]]
    then
        echo_info "Applying custom postgres-ha configuration file"
        /opt/cpm/bin/yq m -i -x "${bootstrap_file}" "/opt/cpm/conf/postgres-ha-config.yaml"
    fi

    if [[ $(cat "${bootstrap_file}") == "---" ]]
    then
        echo_err "postgres-ha configuration file is empty! Please provide a custom config file or enable the base configs."
        exit 1
    else
        echo_info "Finished building postgres-ha configuration file '${bootstrap_file}'"
        cat "${bootstrap_file}"
    fi
}

set_default_pgha_env

env_check_err "PGHA_PATRONI_PORT"
env_check_err "PGHA_PG_PORT"
env_check_err "PGHA_DATABASE"

if [[ "${PGHA_DEFAULT_CONFIG:-true}" == "true" ]]
then
    set_default_patroni_env
fi

set_pg_user_credentials
build_bootstrap_config_file
