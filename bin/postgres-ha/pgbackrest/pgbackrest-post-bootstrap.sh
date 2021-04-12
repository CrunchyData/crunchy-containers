#!/bin/bash

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"

# Create default pgbackrest directories if they don't already exist
create_pgbackrest_dirs() {

    # only create repo dir if using local storage (not if using a central repo or s3/gcs)
    if [[ ! -v PGBACKREST_REPO1_HOST && "${PGBACKREST_REPO1_TYPE}" != "s3" && "${PGBACKREST_REPO1_TYPE}" != "gcs" ]]
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

# Uses the pgBackRest "info" command to verify that the local pgBackRest configuration is valid
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

# Creates the pgBackRest stanza
create_stanza() {
    echo_info "pgBackRest: Executing 'stanza-create' to create stanza '${PGBACKREST_STANZA}'.."
    pgbackrest stanza-create --no-online --log-level-console=info \
        2> /tmp/pgbackrest.stderr
    err=$?
    err_check ${err} "pgBackRest Stanza Creation" \
        "Could not create a pgBackRest stanza: \n$(cat /tmp/pgbackrest.stderr)"
}

# Creates a full backup that will be the initial backup for the database
create_initial_backup() {
    echo_info "pgBackRest: Executing initial pgBackRest backup"
    pgbackrest backup --type=full --pg1-socket-path="/tmp" \
        2> /tmp/pgbackrest.stderr
    err=$?
    err_check ${err} "pgBackRest Initial Backup" \
        "Could not create initial pgBackRest backup: \n$(cat /tmp/pgbackrest.stderr)"
        echo_info "pgBackRest: Initial pgBackRest backup successfully created"
}

# First load pgBackRest env vars set during pre-bootstrap
source "${CRUNCHY_DIR}/bin/postgres-ha/pgbackrest/pgbackrest-set-env.sh"

create_pgbackrest_dirs

# Initialize pgbackrest by validating the configuation, creating the stanza,
# and performing an intial (full) backup
if [[ "${PGHA_PGBACKREST_INITIALIZE}" == "true" ]]
then
    verify_pgbackrest_config
    create_stanza
    create_initial_backup
fi
