#!/bin/bash

# Copyright 2017 - 2019 Crunchy Data Solutions, Inc.
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

source /opt/cpm/bin/common_lib.sh
enable_debugging

PGDATA_PATH_FULL=/pgdata/"${PGDATA_PATH}"
BACKUP_PATH_FULL=/backup/"${BACKUP_PATH}"

# Validate that the proper env vars have been set as needed to restore from a pg_basebackup backup
validate_pgbasebackup_restore_env_vars()  {
    if [[ ! -v PGDATA_PATH ]]
    then
        echo_err "Env var PGDATA_PATH must be set in order to restore from a pg_basebackup backup"
        exit 1
    fi
}

# Validate that the backup directory provided contains a pg database
validate_backup_dir() {
    if [ ! -f "${BACKUP_PATH_FULL}"/postgresql.conf ]
    then
        echo_err "A PostgreSQL db was not found in backup path '${BACKUP_PATH_FULL}'"
        exit 1
    fi
}

# Create an empty pgdata directory for the restore if it does not already exist
create_restore_pgdata_dir()  {
    if [[ ! -d "${PGDATA_PATH_FULL}" ]]
    then
        mkdir -p "${PGDATA_PATH_FULL}"
        echo_info "Created new pgdata directory ${PGDATA_PATH_FULL} for pg_basebackup restore"
    fi
}

# Use rsync to copy backup files to new pgdata directory
rsync_backup()  {

    if [[ "${RSYNC_SHOW_PROGRESS}" == "true" ]]
    then
        progress="--progress"
    fi
    rsync -a $progress --exclude 'pg_log/*' "${BACKUP_PATH_FULL}"/ "${PGDATA_PATH_FULL}" \
        2> /tmp/rsync.stderr
    err_check "$?" "Restore from pg_basebackup backup" \
        "Unable to rsync pg_basebackup backup: \n$(cat /tmp/rsync.stderr)"
    
    echo_info "rysnc of backup into restore directory complete"

    chmod -R 0700 "${PGDATA_PATH_FULL}"
}

# Configure a PITR if a restore target is provided
configure_pitr()  {

    cp /opt/cpm/conf/pitr-recovery.conf /tmp

    if [[ "${RECOVERY_REPLAY_ALL_WAL}" == "true" ]]
    then
        echo_info "Recovering to the end of the WAL log (RECOVERY_REPLAY_ALL_WAL=${RECOVERY_REPLAY_ALL_WAL})"
    elif [[ -v RECOVERY_TARGET_NAME ]]
    then
        sed -i "s/#recovery_target_name.*/recovery_target_name = '${RECOVERY_TARGET_NAME}'/" /tmp/pitr-recovery.conf
        echo_info "Recovering to named restore point '${RECOVERY_TARGET_NAME}' as specified by RECOVERY_TARGET_NAME"
    elif [[ -v RECOVERY_TARGET_TIME ]]
    then
        sed -i "s/#recovery_target_name.*/recovery_target_time = '${RECOVERY_TARGET_TIME}'/" /tmp/pitr-recovery.conf
        echo_info "Recovering to timestamp '${RECOVERY_TARGET_TIME}' as specified by RECOVERY_TARGET_TIME"
    elif [[ -v RECOVERY_TARGET_XID ]]
    then
        sed -i "s/#recovery_target_name.*/recovery_target_xid = '${RECOVERY_TARGET_XID}'/" /tmp/pitr-recovery.conf
        echo_info "Recovering transaction ID '${RECOVERY_TARGET_XID}' as specified by RECOVERY_TARGET_XID"
    fi

    if [[ -v RECOVERY_TARGET_INCLUSIVE ]]
    then
        sed -i "s/#recovery_target_inclusive.*/recovery_target_inclusive = ${RECOVERY_TARGET_INCLUSIVE}/" \
            /tmp/pitr-recovery.conf
        echo_info "Recovering transaction ID '${RECOVERY_TARGET_XID}' as specified by RECOVERY_TARGET_XID",
    fi

    if [ -d "${PGDATA_PATH_FULL}"/pg_wal ]
    then
        #find "${PGDATA_PATH_FULL}"/pg_wal -type f -delete
        rm $"${PGDATA_PATH_FULL}"/pg_wal/*0* "${PGDATA_PATH_FULL}"/pg_wal/archive_status/*0*
        echo_info "Cleaned up pg_wal directory for PITR"
    elif [ -d "${PGDATA_PATH_FULL}"/pg_xlog ]
    then
        #find "${PGDATA_PATH_FULL}"/pg_xlog -type f -delete
        rm "${PGDATA_PATH_FULL}"/pg_xlog/*0* "${PGDATA_PATH_FULL}"/pg_xlog/archive_status/*0*
        echo_info "Cleaned up pg_xlog directory for PITR"
    fi

    cp /tmp/pitr-recovery.conf "${PGDATA_PATH_FULL}"/recovery.conf
    echo_info "Finished preparing recovery.conf for PITR"
}

validate_pgbasebackup_restore_env_vars
validate_backup_dir
create_restore_pgdata_dir

echo_info "Restoring from pg_basebackup backup:"
echo_info "   Backup Path = '${BACKUP_PATH_FULL}'"
echo_info "  Restore Path = '${PGDATA_PATH_FULL}'"
rsync_backup

if [[ -v RECOVERY_TARGET_NAME ]] || [[ -v RECOVERY_TARGET_TIME ]] || [[ -v RECOVERY_TARGET_XID ]] || \
    [[ "${RECOVERY_REPLAY_ALL_WAL}" == "true" ]]
then
    echo_info "Recovery target identified. Preparing a PITR"
    configure_pitr
fi

echo_info "pg_basebackup restore complete"
