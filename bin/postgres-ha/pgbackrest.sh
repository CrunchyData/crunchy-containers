#!/bin/bash

source /opt/cpm/bin/common_lib.sh

# Set default pgbackrest env vars if not explicity provided
set_pgbackrest_env_vars() {

    cluster_name=$(psql -qtAX -c "select current_setting('cluster_name');")

    if [[ ! -v PGBACKREST_STANZA ]]
    then
        export PGBACKREST_STANZA="db"
        default_pgbackrest_env_vars+=("PGBACKREST_STANZA=${PGBACKREST_STANZA}")
    fi

    if [[ ! -v PGBACKREST_PG1_PATH ]] && [[ ! -v PGBACKREST_DB_PATH ]] \
      && [[ ! -v PGBACKREST_DB1_PATH ]]
    then
        pg_path=$(psql -qtAX -c 'show data_directory;')
        export PGBACKREST_PG1_PATH="${pg_path}"
        default_pgbackrest_env_vars+=("PGBACKREST_PG1_PATH=${pg_path}")
    fi

    if [[ ! -v PGBACKREST_REPO1_PATH ]] && [[ ! -v PGBACKREST_REPO_PATH ]]
    then
        export PGBACKREST_REPO1_PATH="/backrestrepo/${cluster_name}-backups"
        default_pgbackrest_env_vars+=("PGBACKREST_REPO1_PATH=${PGBACKREST_REPO1_PATH}")
    fi

    if [[ ! -v PGBACKREST_LOG_PATH ]]
    then
        export PGBACKREST_LOG_PATH="/tmp"
        default_pgbackrest_env_vars+=("PGBACKREST_LOG_PATH=${PGBACKREST_LOG_PATH}")
    fi

    if [[ "${PGBACKREST_ARCHIVE_ASYNC}" == "y" ]]
    then
        if [[ ! -v PGBACKREST_SPOOL_PATH ]] && [[ -v WAL_DIR ]]
        then
            export PGBACKREST_SPOOL_PATH="/pgwal/${cluster_name?}-spool"
            default_pgbackrest_env_vars+=("PGBACKREST_SPOOL_PATH=${PGBACKREST_SPOOL_PATH}")
        elif [[ ! -v PGBACKREST_SPOOL_PATH ]]
        then
            export PGBACKREST_SPOOL_PATH="/pgdata/${cluster_name?}-spool"
            default_pgbackrest_env_vars+=("PGBACKREST_SPOOL_PATH=${PGBACKREST_SPOOL_PATH}")
        fi
    fi

    if [[ ! ${#default_pgbackrest_env_vars[@]} -eq 0 ]]
    then
        echo_info "pgBackRest: Defaults have been set for the following pgbackrest env vars:"
        echo_info "pgBackRest: [${default_pgbackrest_env_vars[*]}]"
    fi
}

# Create default pgbackrest directories if they don't already exist
create_pgbackrest_dirs() {

    # only create repo dir if using local storage (not if using a central repo or 's3')
    if [[ ! -v PGBACKREST_REPO1_HOST && "${PGBACKREST_REPO_TYPE}" != "s3" ]]
    then
        if [[ -v PGBACKREST_REPO_PATH ]]
        then
            repo_dir="${PGBACKREST_REPO_PATH}"
        else
            repo_dir="${PGBACKREST_REPO1_PATH}"
        fi
        
        if [[ ! -d "${repo_dir}" ]]
        then
            mkdir -p "${repo_dir}"
            echo_info "pgBackRest: Created pgbackrest repository directory ${repo_dir}"
        fi
    fi
    
    if [[ ! -d "${PGBACKREST_LOG_PATH}" ]]
    then
        mkdir -p "${PGBACKREST_LOG_PATH}"
        echo_info "pgBackRest: Created pgbackrest logging directory ${PGBACKREST_LOG_PATH}"
    fi

    # Only create spool directories if async archiving enabled
    if [[ "${PGBACKREST_ARCHIVE_ASYNC}" == "y" ]]
    then
        if [[ ! -d "${PGBACKREST_SPOOL_PATH}" ]]
        then
            mkdir -p "${PGBACKREST_SPOOL_PATH}"
            echo_info "pgBackRest: Created async archive spool directory ${PGBACKREST_SPOOL_PATH}"
        fi
    fi
}

verify_pgbackrest_config() {
    echo_info "pgBackRest: Checking if configuration is valid.."
    pgbackrest info > /tmp/pgbackrest.stdout 2> /tmp/pgbackrest.stderr
    err=$?
    err_check ${err} "pgBackRest Configuration Check" \
        "Error with pgBackRest configuration: \n$(cat /tmp/pgbackrest.stderr)"
    if [[ ${err} == 0 ]]
    then
        echo_info "pgBackRest: Configuration is valid"
    fi
}

create_stanza() {
    echo_info "pgBackRest: Executing 'stanza-create' to create stanza '${PGBACKREST_STANZA}'.."
    pgbackrest stanza-create --no-online --log-level-console=info \
        2> /tmp/pgbackrest.stderr
    err=$?
    err_check ${err} "pgBackRest Stanza Creation" \
        "Could not create a pgBackRest stanza: \n$(cat /tmp/pgbackrest.stderr)"
}

set_pgbackrest_env_vars
create_pgbackrest_dirs

env | grep PGBACKREST | while read line ;
do
  echo "export ${line}" >> "/tmp/pgbackrest_env.sh"
done

echo_info "pgBackRest: The following pgbackrest env vars have been set:"
cat "/tmp/pgbackrest_env.sh"

if [[ "${PGHA_PGBACKREST_CREATE_STANZA:-false}" == "true" ]]
then
    verify_pgbackrest_config
    create_stanza
fi
