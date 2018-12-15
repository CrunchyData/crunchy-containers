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

#
# start the backup job
#
# the service looks for the following env vars to be set by
# the cpm-admin that provisioned us
#
# /pgdata is a volume that gets mapped into this container
# $BACKUP_HOST host we are connecting to
# $BACKUP_USER pg user we are connecting with
# $BACKUP_PASS pg user password we are connecting with
# $BACKUP_PORT pg port we are connecting to

set -e

source /opt/cpm/bin/common_lib.sh
enable_debugging

BACKUPBASE=/pgdata/$BACKUP_HOST-backups
if [ ! -d "$BACKUPBASE" ]; then
    echo_info "Creating BACKUPBASE directory as ${BACKUPBASE}.."
    mkdir -p $BACKUPBASE
fi

export BACKUP_LABEL=${BACKUP_LABEL:-crunchybackup}
env_check_info "BACKUP_LABEL" "BACKUP_LABEL is set to ${BACKUP_LABEL}."

TS=`date +%Y-%m-%d-%H-%M-%S`
BACKUP_PATH=$BACKUPBASE/$TS
mkdir $BACKUP_PATH

echo_info "BACKUP_PATH is set to ${BACKUP_PATH}."
echo_info "BACKUP_OPTS is set to ${BACKUP_OPTS}."

export PGPASSFILE=/tmp/pgpass

echo "*:*:*:"$BACKUP_USER":"$BACKUP_PASS  >> $PGPASSFILE

chmod 600 $PGPASSFILE

# chown $UID:$UID $PGPASSFILE

# cat $PGPASSFILE

pg_basebackup --label=$BACKUP_LABEL -X fetch --pgdata $BACKUP_PATH --host=$BACKUP_HOST --port=$BACKUP_PORT -U $BACKUP_USER  $BACKUP_OPTS

# chown -R $UID:$UID $BACKUP_PATH

# Open up permissions for the OSE Dedicated random UID scenario
chmod -R o+rx $BACKUP_PATH

echo_info "Backup has completed."
