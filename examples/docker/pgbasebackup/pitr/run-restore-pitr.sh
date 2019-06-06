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

docker stop pgbasebackup-pitr-restored
docker rm pgbasebackup-pitr-restored

docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}
docker volume rm pitr-restore-pgdata

echo "Starting the ${CONTAINER_NAME} example..."

docker volume create --driver local --name=pitr-restore-pgdata

docker run \
	--volume pitr-restore-pgdata:/pgdata \
	--volume pitr-backup-volume:/backup \
	--env BACKUP_PATH=pitr-backups/2019-05-09-00-03-57 \
	--env PGDATA_PATH=pgbasebackup-pitr-restored \
	--env RECOVERY_TARGET_NAME=beforechanges \
	--name=${CONTAINER_NAME} \
	--hostname=${CONTAINER_NAME} \
	--detach $CCP_IMAGE_PREFIX/crunchy-pgbasebackup-restore:$CCP_IMAGE_TAG
