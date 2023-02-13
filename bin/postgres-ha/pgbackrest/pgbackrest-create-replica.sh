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

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"
enable_debugging

source "${CRUNCHY_DIR}/bin/postgres-ha/common/pgha-common.sh"
export $(get_patroni_pgdata_dir)

source "${CRUNCHY_DIR}/bin/postgres-ha/pgbackrest/pgbackrest-set-env.sh"

bootstrap_role=$1
restore_cmd_args=()

# If initializing a primary for a new cluster and a 'tmp' PGDATA directory exists, then rename
# the 'tmp' directory back to the actual PGDATA directory name in order to perform a delta restore
# below.
tmp_dir="${PATRONI_POSTGRESQL_DATA_DIR}_tmp"
if [[ "${bootstrap_role}" == "primary" ]] && [[ -d "${tmp_dir}" ]]
then
    mv "${tmp_dir}" "${PATRONI_POSTGRESQL_DATA_DIR}"
    err_check "$?" "pgBackRest ${bootstrap_role} Creation" "Could not move PGDATA directory for delta restore"
fi

# If the PGDATA directory is empty or contains a valid PG database, then perform a delta restore.
# If the PGDATA directory for the replica is invalid according to pgBackRest, then clear out
# the directory and then perform a regular (i.e. non-delta) pgBackRest restore.  pgBackRest
# specifically determines whether or not a PGDATA directory is valid by checking "for the
# for the presence of PG_VERSION or backup.manifest (left over from an aborted restore).
# If neither file is found then --delta and --force will be disabled but the restore will proceed
# unless there are files in the $PGDATA directory (or any tablespace directories) in which case the
# operation will be aborted" (https://pgbackrest.org/release.html).
if [[ -f "${PATRONI_POSTGRESQL_DATA_DIR}"/PG_VERSION ||
    -f "${PATRONI_POSTGRESQL_DATA_DIR}"/backup.manifest ]]
then
    echo_info "Valid PGDATA dir found for ${bootstrap_role}, a delta restore will be peformed"
    restore_cmd_args+=("--delta")
elif [[ -z "$(ls -A ${PATRONI_POSTGRESQL_DATA_DIR})" ]]
then
    echo_info "Empty PGDATA dir found for ${bootstrap_role}, a non-delta restore will be peformed"

    # create the PGDATA directory if needed (e.g. in the event it was deleted)
    # and set the proper permissions
    if [[ ! -d "${PATRONI_POSTGRESQL_DATA_DIR}" ]]
    then
        mkdir -p "${PATRONI_POSTGRESQL_DATA_DIR}"
        chmod 0700 "${PATRONI_POSTGRESQL_DATA_DIR}"
    fi
else
    echo_info "Invalid PGDATA directory found for ${bootstrap_role}, cleaning prior to restore"
    while [[ ! -z "$(ls -A ${PATRONI_POSTGRESQL_DATA_DIR})" ]]
    do
        echo_info "Files still found in PGDATA, attempting cleanup"
        rm -rf "${PATRONI_POSTGRESQL_DATA_DIR:?}"/*
        sleep 3
    done
    echo_info "${bootstrap_role} PGDATA cleaned, a non-delta restore will be peformed"
fi

# obtain the type of repo to use for replica creation (e.g. AWS S3, GCS, or local) using the value set
# the 'replica-bootstrap-repo-type' configuration file (if present), and then set the repo type
# for the pgBackRest restore command as applicable using the --repo-type option
if [[ -f /pgconf/replica-bootstrap-repo-type ]]
then
    replica_bootstrap_repo_type="$(cat /pgconf/replica-bootstrap-repo-type)"
    if [[ "${replica_bootstrap_repo_type}" != "" ]]
    then
        restore_cmd_args+=("--repo1-type=${replica_bootstrap_repo_type}")
    fi
fi

# for an S3 repo, if TLS verification is disabled, pass in the appropriate flag
# otherwise, leave the default behavior and verify the S3 server certificate
if [[ ${replica_bootstrap_repo_type} == "s3" && ${PGHA_PGBACKREST_S3_VERIFY_TLS} == "false" ]]
then
    restore_cmd_args+=("--no-repo1-s3-verify-tls")
fi

# Retain and reconfigure existing WAL directory symlink. (By default symlinked directories and
# files are restored as normal directories and files.)
if [[ -n "${PGHA_WALDIR}" ]]
then
    if printf '10\n'${PGVERSION} | sort -VC
    then
        restore_cmd_args+=("--link-map=pg_wal=${PGHA_WALDIR}")
    else
        restore_cmd_args+=("--link-map=pg_xlog=${PGHA_WALDIR}")
    fi
fi

# perform the restore
eval "pgbackrest restore ${restore_cmd_args[*]} ${RESTORE_OPTS}"
err_check "$?" "pgBackRest ${bootstrap_role} Creation" "pgBackRest restore failed when creating ${bootstrap_role}"

echo_info "${bootstrap_role} pgBackRest restore complete"
