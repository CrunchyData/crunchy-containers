#!/bin/bash

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"

# Set default pgbackrest env vars if not explicity provided
set_pgbackrest_env_vars() {

    if [[ -v PATRONI_SCOPE ]]
    then
        patroni_cluster_name="${PATRONI_SCOPE}"
    else
        patroni_cluster_name=$("${CRUNCHY_DIR}/bin/yq" r /tmp/postgres-ha-bootstrap.yaml scope)
    fi

    if [[ -v PATRONI_POSTGRESQL_DATA_DIR ]]
    then
        pg_data_dir="${PATRONI_POSTGRESQL_DATA_DIR}"
    else
        pg_data_dir=$("${CRUNCHY_DIR}/bin/yq" r /tmp/postgres-ha-bootstrap.yaml postgresql.data_dir)
    fi

    if [[ ! -v PGBACKREST_STANZA ]]
    then
        export PGBACKREST_STANZA="db"
        default_pgbackrest_env_vars+=("PGBACKREST_STANZA=${PGBACKREST_STANZA}")
    fi

    if [[ ! -v PGBACKREST_PG1_PATH ]] && [[ ! -v PGBACKREST_DB_PATH ]] \
      && [[ ! -v PGBACKREST_DB1_PATH ]]
    then
        export PGBACKREST_PG1_PATH="${pg_data_dir}"
        default_pgbackrest_env_vars+=("PGBACKREST_PG1_PATH=${pg_path}")
    fi

    if [[ ! -v PGBACKREST_REPO1_PATH ]] && [[ ! -v PGBACKREST_REPO_PATH ]]
    then
        export PGBACKREST_REPO1_PATH="/backrestrepo/${patroni_cluster_name}-backups"
        default_pgbackrest_env_vars+=("PGBACKREST_REPO1_PATH=${PGBACKREST_REPO1_PATH}")
    fi

    if [[ ! -v PGBACKREST_LOG_PATH ]]
    then
        export PGBACKREST_LOG_PATH="/tmp"
        default_pgbackrest_env_vars+=("PGBACKREST_LOG_PATH")
    fi

    if [[ "${PGBACKREST_ARCHIVE_ASYNC}" == "y" ]]
    then
        if [[ ! -v PGBACKREST_SPOOL_PATH ]] && [[ -v WAL_DIR ]]
        then
            export PGBACKREST_SPOOL_PATH="/pgwal/${patroni_cluster_name?}-spool"
            default_pgbackrest_env_vars+=("PGBACKREST_SPOOL_PATH")
        elif [[ ! -v PGBACKREST_SPOOL_PATH ]]
        then
            export PGBACKREST_SPOOL_PATH="/pgdata/${patroni_cluster_name?}-spool"
            default_pgbackrest_env_vars+=("PGBACKREST_SPOOL_PATH")
        fi
    fi

    if [[ ! ${#default_pgbackrest_env_vars[@]} -eq 0 ]]
    then
        echo_info "pgBackRest: Defaults have been set for the following pgbackrest env vars:"
        echo_info "pgBackRest: [${default_pgbackrest_env_vars[*]}]"
    fi
}

set_pgbackrest_env_vars

# save pgbackrest env vars so they can be restored as needed to execute pgbackrest commands
export -p | grep "^declare -x PGBACKREST" > "/tmp/pgbackrest_env.sh"
