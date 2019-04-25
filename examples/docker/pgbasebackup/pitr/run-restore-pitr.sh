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

CONTAINER_NAME=restore-pitr

echo "Cleaning up..."

sudo docker stop ${CONTAINER_NAME}
sudo docker rm ${CONTAINER_NAME}
docker volume rm pitr-restore

echo "Starting the ${CONTAINER_NAME} example..."

docker volume create --driver local --name=pitr-restore

sudo docker run \
	-e RECOVERY_TARGET_NAME=beforechanges \
	-p 12001:5432 \
	-v pitr-restore:/pgdata \
	-v pitr-backup-volume:/backup \
	-v pitr-wal:/recover \
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
	-e WAL_DIR=pitr-wal \
	-e BACKUP_PATH=pitr-backups/2019-03-08-15-04-02 \
	--name=${CONTAINER_NAME} \
	--hostname=${CONTAINER_NAME} \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG
