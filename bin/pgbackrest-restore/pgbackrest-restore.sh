#!/bin/bash

# Copyright 2017 - 2023 Crunchy Data Solutions, Inc.
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

set -e

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/restore_common_lib.sh"
enable_debugging

# Warn the user of any deprecated env vars due to full transition to env vars for configuring 
check_for_deprecated_env_vars()  {
    
    if [[ -v STANZA ]] && [[ ! -v PGBACKREST_STANZA ]]
    then
        echo_warn "STANZA has been deprecated and will be removed in a future release - please use PGBACKREST_STANZA instead."
        echo_warn "PGBACKREST_STANZA will be set to '${STANZA}' for this restore."
        export PGBACKREST_STANZA="${STANZA}"
    fi
    
    if [[ -v DELTA ]] && [[ ! -v PGBACKREST_DELTA ]]
    then
        echo_warn "DELTA has been deprecated and will be removed in a future release - please use PGBACKREST_DELTA instead."
        echo_warn "PGBACKREST_DELTA will be set to 'y' as a result of setting DELTA for this restore."
        export PGBACKREST_DELTA="y"
    fi

    if [[ -v PITR_TARGET ]] && [[ ! -v PGBACKREST_TARGET ]]
    then
        echo_warn "PITR_TARGET has been deprecated and will be removed in a future release - please use PGBACKREST_TARGET instead."
        echo_warn "PGBACKREST_TARGET will be set to the value specified for PITR_TARGET for this restore."
        export PGBACKREST_TARGET="${PITR_TARGET}"
    fi

    if [[ -v BACKREST_CUSTOM_OPTS ]]
    then
        echo_warn "BACKREST_CUSTOM_OPTS has been deprecated and will be removed in a future release."
        echo_warn "Please use applicable pgbackrest env vars to customize your pgbackrest restore instead."
    fi

    if [[ -v PG_HOSTNAME && \
      ( ! -v PGBACKREST_PG1_PATH && ! -v PGBACKREST_DB1_PATH && ! -v PGBACKREST_DB_PATH ) ]]
    then
        echo_warn "PG_HOSTNAME has been deprecated and will be removed in a future release - please use PGBACKREST_PG1_PATH instead."
        echo_warn "PGBACKREST_PG1_PATH will be set to '/pgdata/${PG_HOSTNAME}' for this restore."
        export PGBACKREST_PG1_PATH="/pgdata/${PG_HOSTNAME}"
    fi
}

display_config_details()  {
    if [[ -v PGBACKREST_DELTA ]]
    then
        echo_info "Delta restore detected."
    fi
    
    if [[ -v PGBACKREST_TYPE ]]
    then
        echo_info "The following type of recovery will be attempted: ${PGBACKREST_TYPE:-default}" 
        if [[ -v PGBACKREST_TARGET ]]
        then
            echo_info "The target for the restore is: ${PGBACKREST_TARGET}"
        fi
    fi
}

# create an empty pgdata directory for a full restore if it does not already exist
create_restore_pgdata_dir()  {
    if [[ -v PGBACKREST_PG1_PATH ]]
    then
        pgdata_dir="${PGBACKREST_PG1_PATH}"
    elif [[ -v PGBACKREST_DB1_PATH ]]
    then
        pgdata_dir="${PGBACKREST_DB1_PATH}"
    elif [[ -v PGBACKREST_DB_PATH ]]
    then
        pgdata_dir="${PGBACKREST_DB_PATH}"
    fi

    if [[ ! -d "${pgdata_dir}" ]]
    then
        mkdir -p "${pgdata_dir}"
        echo_info "Created new pgdata directory ${pgdata_dir}"
    fi
}

check_for_deprecated_env_vars
display_config_details
create_restore_pgdata_dir

echo_info "Starting restore.."
echo_info "The following pgbackrest env vars have been set:"
( set -o posix ; set | grep -oP "^PGBACKREST.*" )

echo_info "Initiating pgbackrest restore.."
pgbackrest restore ${BACKREST_CUSTOM_OPTS:-}
echo_info "Restore completed.  Exiting.."

exit 0
