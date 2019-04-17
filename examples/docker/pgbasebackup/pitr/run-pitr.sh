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

CONTAINER_NAME=pitr

echo "Cleaning up..."

sudo docker stop ${CONTAINER_NAME}
sudo docker rm ${CONTAINER_NAME}
docker volume rm pitr-pgdata
docker volume rm pitr-wal
docker network rm pitrnet

echo "Starting the ${CONTAINER_NAME} example..."

docker network create --driver bridge pitrnet

sudo docker run \
	-p 12000:5432 \
	-v pitr-pgdata:/pgdata \
	-v pitr-wal:/pgwal \
	-e TEMP_BUFFERS=9MB \
	-e PGHOST=/tmp \
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
	-e ARCHIVE_MODE=on \
	-e ARCHIVE_TIMEOUT=60 \
	--name=${CONTAINER_NAME} \
	--hostname=${CONTAINER_NAME} \
	--network=pitrnet \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG
