#!/bin/bash

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
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

CONTAINER_NAME=restore-pitr

echo "Cleaning up..."

sudo docker stop ${CONTAINER_NAME}
sudo docker rm ${CONTAINER_NAME}

echo "Starting the ${CONTAINER_NAME} example..."

# uncomment these lines to override the pg config files with
# your own versions of pg_hba.conf and postgresql.conf
#PGCONF=$HOME/openshift-dedicated-container/pgconf
#sudo chown postgres:postgres $PGCONF
#sudo chmod 0700 $PGCONF
#sudo chcon -Rt svirt_sandbox_file_t $PGCONF
# add this next line to the docker run to override pg config files

# the following path is where the base backup files
# are located for doing the database restore
BACKUP=/tmp/backups/pitr-backups/2018-04-05-18-39-54

# WAL_DIR contains the WAL files generated from
# this database after recovery and ongoing afterwards
WAL_DIR=/tmp/${CONTAINER_NAME}-wal

# RECOVER_DIR contains the WAL files from where we
# want to recover from
RECOVER_DIR=/tmp/pitr/pitr/pg_wal

DATA_DIR=/tmp/${CONTAINER_NAME}
sudo rm -rf $DATA_DIR $WAL_DIR
sudo mkdir -p $DATA_DIR $WAL_DIR
sudo chown postgres:postgres $DATA_DIR $WAL_DIR
sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR $WAL_DIR
#	-e RECOVERY_TARGET_NAME=beforechanges \
#	-e RECOVERY_TARGET_NAME=afterchanges \
#	-e RECOVERY_TARGET_TIME='2016-09-21 16:05:00' \

sudo docker run \
	-e RECOVERY_TARGET_NAME=beforechanges \
	-p 12001:5432 \
	-v $DATA_DIR:/pgdata \
	-v $WAL_DIR:/pgwal \
	-v "$BACKUP":/backup \
	-v $RECOVER_DIR:/recover \
	-e ARCHIVE_MODE=on \
	-e ARCHIVE_TIMEOUT=60 \
	-e TEMP_BUFFERS=9MB \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e WORK_MEM=5MB \
	-e PG_MODE=primary \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_PRIMARY_PASSWORD=password \
	-e PG_PRIMARY_PORT=5432 \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=${CONTAINER_NAME} \
	--hostname=${CONTAINER_NAME} \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG
