#!/bin/bash

# Copyright 2019 - 2023 Crunchy Data Solutions, Inc.
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

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"

echo_info "postgres-ha pre-bootstrap starting..."

# Set defaults for the various auto-configuration options that can be enabled/disabled
set_default_pgha_autoconfig_env()  {

    if [[ ! -v PGHA_DEFAULT_CONFIG ]]
    then
        export PGHA_DEFAULT_CONFIG="true"
        default_pgha_autoconfig_env_vars+=("PGHA_DEFAULT_CONFIG")
    fi

    if [[ ! -v PGHA_BASE_BOOTSTRAP_CONFIG ]]
    then
        export PGHA_BASE_BOOTSTRAP_CONFIG="true"
        default_pgha_autoconfig_env_vars+=("PGHA_BASE_BOOTSTRAP_CONFIG")
    fi

    if [[ ! -v PGHA_BASE_PG_CONFIG ]]
    then
        export PGHA_BASE_PG_CONFIG="true"
        default_pgha_autoconfig_env_vars+=("PGHA_BASE_PG_CONFIG")
    fi

    if [[ ! -v PGHA_PGBACKREST ]]
    then
        export PGHA_PGBACKREST="true"
        default_pgha_autoconfig_env_vars+=("PGHA_PGBACKREST")
        if [[ ! -v PGHA_PGBACKREST_LOCAL_S3_STORAGE ]]
        then
            export PGHA_PGBACKREST_LOCAL_S3_STORAGE="false"
            default_pgha_autoconfig_env_vars+=("PGHA_PGBACKREST_LOCAL_S3_STORAGE")
        fi
        if [[ ! -v PGHA_PGBACKREST_INITIALIZE ]]
        then
            export PGHA_PGBACKREST_INITIALIZE="false"
            default_pgha_autoconfig_env_vars+=("PGHA_PGBACKREST_INITIALIZE")
        fi
    else
        echo_info "pgBackRest auto-config disabled"
        echo_info "PGHA_PGBACKREST_LOCAL_S3_STORAGE and PGHA_PGBACKREST_INITIALIZE will be ignored if provided"
    fi

    if [[ ! -v PGHA_SYNC_REPLICATION ]]
    then
        export PGHA_SYNC_REPLICATION="false"
        default_pgha_autoconfig_env_vars+=("PGHA_SYNC_REPLICATION")
    fi

    if [[ ! -v PGHA_STANDBY ]]
    then
        export PGHA_STANDBY="false"
        default_pgha_autoconfig_env_vars+=("PGHA_STANDBY")
    fi

    if [[ ! ${#default_pgha_autoconfig_env_vars[@]} -eq 0 ]]
    then
        pgha_autoconfig_env_vars=$(printf ', %s' "${default_pgha_autoconfig_env_vars[@]}")
        echo_info "Defaults have been set for the following postgres-ha auto-configuration env vars: ${pgha_autoconfig_env_vars:2}"
    fi
}

# Set defaults for the custom crunchy-postgres-ha env vars required to bootstrap a cluster
set_default_pgha_env()  {

    if [[ ! -v PGHA_PATRONI_PORT ]]
    then
        export PGHA_PATRONI_PORT="8009"
        default_pgha_env_vars+=("PGHA_PATRONI_PORT")
    fi

    if [[ ! -v PGHA_PG_PORT ]]
    then
        export PGHA_PG_PORT="5432"
        default_pgha_env_vars+=("PGHA_PG_PORT")
    fi

    if [[ ! -v PGHA_DATABASE ]]
    then
        export PGHA_DATABASE="userdb"
        default_pgha_env_vars+=("PGHA_DATABASE")
    fi

    if [[ ! -v PGHA_REPLICA_REINIT_ON_START_FAIL ]]
    then
        export PGHA_REPLICA_REINIT_ON_START_FAIL="true"
        pgha_env_vars+=("PGHA_REPLICA_REINIT_ON_START_FAIL")
    fi

    if [[ ! ${#default_pgha_env_vars[@]} -eq 0 ]]
    then
        pgha_env_vars=$(printf ', %s' "${default_pgha_env_vars[@]}")
        echo_info "Defaults have been set for the following postgres-ha env vars: ${pgha_env_vars:2}"
    fi
}

# Set default Patroni environment variables
set_default_patroni_env() {

    host_ip=$(hostname -i)

    if [[ ! -v PATRONI_NAME ]]
    then
        export PATRONI_NAME="${HOSTNAME}"
        default_patroni_env_vars+=("PATRONI_NAME")
    fi

    if [[ ! -v PATRONI_SCOPE ]]
    then
        export PATRONI_SCOPE="example-cluster"
        default_patroni_env_vars+=("PATRONI_SCOPE")
    fi

    if [[ ! -v PATRONI_RESTAPI_LISTEN ]]
    then
        export PATRONI_RESTAPI_LISTEN="0.0.0.0:${PGHA_PATRONI_PORT}"
        default_patroni_env_vars+=("PATRONI_RESTAPI_LISTEN")
    fi

    if [[ ! -v PATRONI_RESTAPI_CONNECT_ADDRESS ]]
    then
        export PATRONI_RESTAPI_CONNECT_ADDRESS="${host_ip}:${PGHA_PATRONI_PORT}"
        default_patroni_env_vars+=("PATRONI_RESTAPI_CONNECT_ADDRESS")
    fi

    if [[ ! -v PATRONI_POSTGRESQL_LISTEN ]]
    then
        export PATRONI_POSTGRESQL_LISTEN="0.0.0.0:${PGHA_PG_PORT}"
        default_patroni_env_vars+=("PATRONI_POSTGRESQL_LISTEN")
    fi

    if [[ ! -v PATRONI_POSTGRESQL_CONNECT_ADDRESS ]]
    then
        export PATRONI_POSTGRESQL_CONNECT_ADDRESS="${host_ip}:${PGHA_PG_PORT}"
        default_patroni_env_vars+=("PATRONI_POSTGRESQL_CONNECT_ADDRESS")
    fi

    if [[ ! -v PATRONI_POSTGRESQL_DATA_DIR ]]
    then
        export PATRONI_POSTGRESQL_DATA_DIR="/pgdata/${HOSTNAME}"
        default_patroni_env_vars+=("PATRONI_POSTGRESQL_DATA_DIR")
    fi

    if [[ ! ${#default_patroni_env_vars[@]} -eq 0 ]]
    then
        pgha_env_vars=$(printf ', %s' "${default_patroni_env_vars[@]}")
        echo_info "Defaults have been set for the following Patroni env vars: ${pgha_env_vars:2}"
    fi
}

# Set the PG user credentials for Patroni & post-bootstrap using the file system (e.g. Kube secrets)
set_pg_user_credentials() {
    echo_info "Setting postgres-ha configuration for database user credentials"

    if [[ -d "/pgconf/pguser" ]]
    then
	    echo_info "Setting 'pguser' credentials using file system"

	    PGHA_USER=$(cat /pgconf/pguser/username)
        err_check "$?" "Set postgres-ha user" "Unable to set PGHA_USER using secret"
	    export PGHA_USER

        PGHA_USER_PASSWORD=$(cat /pgconf/pguser/password)
        err_check "$?" "Set postgres-ha user password" "Unable to set PGHA_USER_PASSWORD using secret"
        export PGHA_USER_PASSWORD
    else
        env_check_err "PGHA_USER"
        env_check_err "PGHA_USER_PASSWORD"
    fi

    if [[ -d "/pgconf/pgsuper" ]]
    then
        echo_info "Setting 'superuser' credentials using file system"

        PATRONI_SUPERUSER_USERNAME=$(cat /pgconf/pgsuper/username)
        err_check "$?" "Set superuser" "Unable to set PATRONI_SUPERUSER_USERNAME using secret"
        export PATRONI_SUPERUSER_USERNAME

        PATRONI_SUPERUSER_PASSWORD=$(cat /pgconf/pgsuper/password)
        err_check "$?" "Set superuser password" "Unable to set PATRONI_SUPERUSER_PASSWORD using secret"
        export PATRONI_SUPERUSER_PASSWORD
    else
        env_check_err "PATRONI_SUPERUSER_USERNAME"
        env_check_err "PATRONI_SUPERUSER_PASSWORD"
    fi

    if [[ -d "/pgconf/pgreplicator" ]]
    then
        echo_info "Setting 'replicator' credentials using file system"

        PATRONI_REPLICATION_USERNAME=$(cat /pgconf/pgreplicator/username)
        err_check "$?" "Set replication user" "Unable to set PATRONI_REPLICATION_USERNAME using secret"
        export PATRONI_REPLICATION_USERNAME

        PATRONI_REPLICATION_PASSWORD=$(cat /pgconf/pgreplicator/password)
        err_check "$?" "Set replication user password" "Unable to set PATRONI_REPLICATION_PASSWORD using secret"
        export PATRONI_REPLICATION_PASSWORD
    else
        env_check_err "PATRONI_REPLICATION_USERNAME"
        env_check_err "PATRONI_REPLICATION_PASSWORD"
    fi
}

# Sets the bootstrap method for the cluster.  Can either be 'initdb' to initialize a new cluster
# from scratch, 'pgbackrest_init' to initialize using a pgBackRest restore, or 'existing_init' to
# initialize from an existing PGDATA directory.
set_bootstrap_method() {
    if [[ ! -v PGHA_BOOTSTRAP_METHOD ]]
    then
        if [[ -d "${PATRONI_POSTGRESQL_DATA_DIR}" && -n "$(ls -A "${PATRONI_POSTGRESQL_DATA_DIR}")" ]]
        then
            export PGHA_BOOTSTRAP_METHOD="existing_init"
        else
            export PGHA_BOOTSTRAP_METHOD="initdb"
        fi
    fi
}

# Validate environment variables
validate_env() {
    if [[ "${PATRONI_POSTGRESQL_DATA_DIR}" == "/pgdata" || "${PATRONI_POSTGRESQL_DATA_DIR}" == "/pgdata/"
        || ! "${PATRONI_POSTGRESQL_DATA_DIR:0:8}" == "/pgdata/" ]]
    then
        echo_err "The PGDATA directory provided using PATRONI_POSTGRESQL_DATA_DIR must be a subdirectory of volume /pgdata"
        exit 1
    fi
    if [[ -n "${PGHA_WALDIR}" ]]
    then
        if [[ "${PGHA_WALDIR}" == "/pgwal" || "${PGHA_WALDIR}" == "/pgwal/" || ! "${PGHA_WALDIR:0:7}" == "/pgwal/" ]]
        then
            echo_err "PGHA_WALDIR must be a subdirectory of volume /pgwal.  Directory ${PGHA_WALDIR} provided"
            exit 1
        fi
    fi
}

# Build the Patroni bootstrap configuration file
build_bootstrap_config_file() {

    bootstrap_file="/tmp/postgres-ha-bootstrap.yaml"
    echo "---" > "${bootstrap_file}"

    pghba_file="/tmp/postgres-ha-pghba.yaml"
    cat "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-pghba-bootstrap.yaml" > "${pghba_file}"

    if [[ "${PGHA_BASE_BOOTSTRAP_CONFIG}" == "true" ]]
    then
        echo_info "Applying base bootstrap config to postgres-ha configuration"
        "${CRUNCHY_DIR}/bin/yq" m -i -x "${bootstrap_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-bootstrap.yaml"
        # set the configured bootstrap method (e.g. initdb or pgbackrest)
        sed -i "s/PGHA_BOOTSTRAP_METHOD/$PGHA_BOOTSTRAP_METHOD/g" "${bootstrap_file}"
    else
        echo_info "Base bootstrap config for postgres-ha configuration disabled"
    fi

    if [[ "${PGHA_BASE_PG_CONFIG}" == "true" ]]
    then
        echo_info "Applying base postgres config to postgres-ha configuration"
        "${CRUNCHY_DIR}/bin/yq" m -i -x "${bootstrap_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-pgconf.yaml"
    else
        echo_info "Base PG config for postgres-ha configuration disabled"
    fi

    if [[ "${PGHA_PGBACKREST}" == "true" ]]
    then
        echo_info "Applying pgbackrest config to postgres-ha configuration"
        "${CRUNCHY_DIR}/bin/yq" m -i -x "${bootstrap_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-pgbackrest.yaml"
        if [[ "${PGHA_PGBACKREST_LOCAL_S3_STORAGE}" == "true" ]]
        then
            ${CRUNCHY_DIR}/bin/yq m -i -x "${bootstrap_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-pgbackrest-local-s3.yaml"
        fi
    else
        echo_info "pgBackRest config for postgres-ha configuration disabled"
    fi

    if [[ "${PGHA_INIT}" == "true" ]]
    then
        "${CRUNCHY_DIR}/bin/yq" m -i -x "${bootstrap_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-initdb.yaml"

        if [[ -n "${PGHA_WALDIR}" ]]
        then
            echo_info "Applying custom WAL dir to postgres-ha configuration"
            if printf '10\n'${PGVERSION} | sort -VC
            then
                "${CRUNCHY_DIR}/bin/yq" w -i "${bootstrap_file}" 'bootstrap.initdb[+].waldir' "${PGHA_WALDIR}"
            else
                "${CRUNCHY_DIR}/bin/yq" w -i "${bootstrap_file}" 'bootstrap.initdb[+].xlogdir' "${PGHA_WALDIR}"
            fi
        fi
    fi

    if [[ "${PGHA_STANDBY}" == "true" ]]
    then
        echo_info "Applying configuration to bootstrap a standby cluster"
        "${CRUNCHY_DIR}/bin/yq" m -i -x "${bootstrap_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-standby.yaml"
    fi

    if [[ "${PGHA_SYNC_REPLICATION}" == "true" ]]
    then
        echo_info "Applying synchronous replication settings to postgres-ha configuration"
        "${CRUNCHY_DIR}/bin/yq" m -i -x "${bootstrap_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-sync.yaml"
    fi

    # set up the pg_hba.conf file, based on if the user has enabled TLS, and if
    # TLS is required. This involves appending data to the special pghba_file
    # and then finally merging it into the main file
    #
    # Additionally, this will also merge append the TLS settings to the main
    # postgresql.conf file
    if [[ "${PGHA_TLS_ENABLED}" == "true" ]]
    then
      echo_info "Enabling TLS"
      pghba_tls_file="${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-pghba-tls.yaml"

      # if there is a TLS keypair for a replication user detected, we will need
      # to copy this to a special mount in order to properly enable
      # certificate-based authentication between replicas. This is due to
      # PostgreSQL requiring a client's TLS key to have permissions no less strict
      # than 0600. In this case, the client is the "postgres" user, and because
      # Kubernetes Secrets are owned by the group, we need to create a copy of
      # this key with the correct permissions
      if [[ -f "/pgconf/tls/tls-replication.key" ]] && [[ -f "/pgconf/tls/tls-replication.crt" ]]
      then
        echo_info "Enabling certificate-based authentication for replication"

        tls_replication_key_file="/pgconf/tls-replication/tls.key"
        tls_replication_cert_file="/pgconf/tls-replication/tls.crt"
        touch "${tls_replication_key_file}" "${tls_replication_cert_file}"
        install -m 0600 /pgconf/tls/tls-replication.key "${tls_replication_key_file}"
        install -m 0600 /pgconf/tls/tls-replication.crt "${tls_replication_cert_file}"

        # update the bootstrap parameters to set the certificate-based
        # authentication settings
        "${CRUNCHY_DIR}/bin/yq" w -i "${bootstrap_file}" postgresql.authentication.replication.sslkey "${tls_replication_key_file}"
        "${CRUNCHY_DIR}/bin/yq" w -i "${bootstrap_file}" postgresql.authentication.replication.sslcert "${tls_replication_cert_file}"
        "${CRUNCHY_DIR}/bin/yq" w -i "${bootstrap_file}" postgresql.authentication.replication.sslrootcert "/pgconf/tls/ca.crt"
        # as we have the CA available, we can make the TLS mode "verify-ca" by
        # default
        "${CRUNCHY_DIR}/bin/yq" w -i "${bootstrap_file}" postgresql.authentication.replication.sslmode "verify-ca"
        # if a CRL file is provided, add this to the stanza as well
        if [[ -f "/pgconf/tls/ca.crl" ]]
        then
          "${CRUNCHY_DIR}/bin/yq" w -i "${bootstrap_file}" postgresql.authentication.replication.sslcrl "/pgconf/tls/ca.crl"
        fi

        # use an updated pg_hba.conf file that enforces certificate based
        # authentication
        pghba_tls_file="${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-pghba-tls-auth.yaml"
      fi

      echo_info "Applying TLS remote connection configuration to pg_hba.conf"
      "${CRUNCHY_DIR}/bin/yq" m -i -a "${pghba_file}" "${pghba_tls_file}"
      echo_info "Enabling TLS in postgresql.conf"
      "${CRUNCHY_DIR}/bin/yq" m -i -a "${bootstrap_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-pgconf-tls.yaml"

      # The CRL file may not be present, so we only want to apply if if we have
      # the CRL file present
      if [[ -f "/pgconf/tls/ca.crl" ]]
      then
        "${CRUNCHY_DIR}/bin/yq" w -i "${bootstrap_file}" bootstrap.dcs.postgresql.parameters.ssl_crl_file "/pgconf/tls/ca.crl"
      fi
    fi

    if [[ "${PGHA_TLS_ONLY}" != "true" ]]
    then
      echo_info "Applying standard (non-TLS) remote connection configuration to pg_hba.conf"
      "${CRUNCHY_DIR}/bin/yq" m -i -a "${pghba_file}" "${CRUNCHY_DIR}/conf/postgres-ha/postgres-ha-pghba-notls.yaml"
    fi

    # If this is being restored to a new cluster, disable archive_mode to
    # prevent WAL from being pushed while potentiallystill connected to another
    # pgBackRest repository while initializing (e.g. while performing a
    # pgBackRest restore).
    #
    # Otherwise, ensure that archive_mode is set explicitly to on.
    if [[ "${PGHA_BOOTSTRAP_METHOD}" == "pgbackrest_init" ]]
    then
        # get the name of the cluster source from the pgBackRest repository
        if [[ "${PGBACKREST_REPO1_PATH}" =~ \/backrestrepo\/(.*)-backrest-shared-repo$ ]];
        then
            bootstrap_cluster_source="${BASH_REMATCH[1]}"
        fi

        # get the name of the cluster target
        if [[ "${PGBACKREST_DB_PATH}" =~ \/pgdata\/(.*)$ ]];
        then
            bootstrap_cluster_target="${BASH_REMATCH[1]}"
        fi

        if [[ "${bootstrap_cluster_source}" != "${bootstrap_cluster_target}" ]];
        then
            echo_info "Disabling archiving for bootstrap method ${PGHA_BOOTSTRAP_METHOD}"
            "${CRUNCHY_DIR}/bin/yq" w -i --style=single "${bootstrap_file}" postgresql.parameters.archive_command "false"
        fi
    fi

    # merge the pg_hba.conf settings into the main bootstrap file
    sed -i "s/PATRONI_REPLICATION_USERNAME/$PATRONI_REPLICATION_USERNAME/g" "${pghba_file}"
    "${CRUNCHY_DIR}/bin/yq" m -i -x "${bootstrap_file}" "${pghba_file}"

    if [[ -f "/pgconf/postgres-ha.yaml" ]]
    then
        echo_info "Applying custom postgres-ha configuration file"
        "${CRUNCHY_DIR}/bin/yq" m -i -x "${bootstrap_file}" "/pgconf/postgres-ha.yaml"
    else
        echo_info "Custom postgres-ha configuration file not detected"
    fi

    if [[ $(cat "${bootstrap_file}") == "---" ]]
    then
        echo_err "postgres-ha configuration file is empty! Please provide a custom config file or enable the base configs."
        exit 1
    else
        echo_info "Finished building postgres-ha configuration file '${bootstrap_file}'"
    fi
}

# Set and logs defaults for postgres-ha (PGHA) env vars
set_default_pgha_autoconfig_env
set_default_pgha_env
pgha_print_env=$(env | grep "^PGHA_")

# Set and log defaults for Patroni env vars (if default config is enabled)
if [[ "${PGHA_DEFAULT_CONFIG}" == "true" ]]
then
    env_check_err "PGHA_PATRONI_PORT"
    env_check_err "PGHA_PG_PORT"
    env_check_err "PGHA_DATABASE"
    set_default_patroni_env
else
    echo_info "Defaults will not be set for Patroni environment variables"
fi
patroni_print_env=$(env | grep "^PATRONI_")  # capture Patroni env prior to setting credentials to them keep out of logs

# Set user credentials using the file system (e.g. Kube secrets) if provided
set_pg_user_credentials

# Sets the proper bootstrap method for the cluster ('initdb', 'pgbackrest_init' or 'existing_init')
set_bootstrap_method

# Perform any additional validation of env vars required
validate_env

# Create the Patroni bootstrap configuration file
build_bootstrap_config_file

# If the PGHA_INIT flag is 'true' and data exists within the PGDATA directory, then proceed with
# preparing the PGDATA directory for cluster bootstrap.  Specifically, assume we are using a
# bootstrap method that is able to leverage an existing PGDATA directory (for instance, if starting
# the database that already exists within the PGDATA directory, or if performing a pgBackRest delta
# restore), and temporarily rename the existing PGDATA directory so that the true PGDATA directory
# remains empty.  This will cause Patroni to bootstrap a new PostgreSQL cluster from scratch, while
# still allowing the configured bootstrap method to leverage any existing data within the PGDATA
# directory as needed.
if [[ "${PGHA_INIT}" == "true" ]] &&
    [[ -d "${PATRONI_POSTGRESQL_DATA_DIR}" && -n "$(ls -A "${PATRONI_POSTGRESQL_DATA_DIR}")" ]]
then
    echo_info "Detected cluster initialization using an existing PGDATA directory"
    mv "${PATRONI_POSTGRESQL_DATA_DIR}" "${PATRONI_POSTGRESQL_DATA_DIR}_tmp"
    err_check "$?" "Initialize Existing PGDATA" "Could not move the existing PGDATA directory as needed to initialize"
else
    # Create the pgdata directory if it doesn't exist
    mkdir -p "${PATRONI_POSTGRESQL_DATA_DIR}"
    chmod 0700 "${PATRONI_POSTGRESQL_DATA_DIR}"
fi

# create any tablespace directories, if they have not been created yet
source "${CRUNCHY_DIR}/bin/postgres-ha/common/pgha-tablespaces.sh"
tablespaces_create_directory

echo_info "postgres-ha pre-bootstrap complete!  The following configuration will be utilized to initialize " \
"this postgres-ha node:"
echo "******************************"
echo "postgres-ha (PGHA) env vars:"
echo "******************************"
echo "${pgha_print_env}"
echo "******************************"
echo "Patroni env vars:"
echo "******************************"
echo "${patroni_print_env}"
echo "******************************"
echo "Patroni bootstrap method: ${PGHA_BOOTSTRAP_METHOD}"
echo "******************************"
echo "Patroni configuration file:"
echo "******************************"
cat ${bootstrap_file}
