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

echo "Starting the sync example..."

PRIMARY_CONTAINER_NAME=primarysync
SYNC_CONTAINER_NAME=replicasync
ASYNC_CONTAINER_NAME=replicaasync

echo "Starting the ${PRIMARY_CONTAINER_NAME} container..."

sudo docker stop ${PRIMARY_CONTAINER_NAME}
sudo docker rm ${PRIMARY_CONTAINER_NAME}
docker volume rm ${PRIMARY_CONTAINER_NAME}-pgdata

sudo docker run \
	-p 12010:5432 \
	-v ${PRIMARY_CONTAINER_NAME}-pgdata:/pgdata \
	-e PGHOST=/tmp \
	-e TEMP_BUFFERS=9MB \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e WORK_MEM=5MB \
	-e PG_MODE=primary \
	-e SYNC_REPLICA=${SYNC_CONTAINER_NAME} \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_PRIMARY_PASSWORD=password \
	-e PG_PRIMARY_PORT=5432 \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=${PRIMARY_CONTAINER_NAME} \
	--hostname=${PRIMARY_CONTAINER_NAME} \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG

echo "Sleeping in order to let the ${PRIMARY_CONTAINER_NAME} container start..."
sleep 20

echo "Starting the ${SYNC_CONTAINER_NAME} container..."

sudo docker stop ${SYNC_CONTAINER_NAME}
sudo docker rm ${SYNC_CONTAINER_NAME}
docker volume rm ${SYNC_CONTAINER_NAME}-pgdata

sudo docker run \
	-p 12011:5432 \
	-v ${SYNC_CONTAINER_NAME}-pgdata:/pgdata \
	-e PGHOST=/tmp \
	-e TEMP_BUFFERS=9MB \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e WORK_MEM=5MB \
	-e PG_MODE=replica \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_PRIMARY_PASSWORD=password \
	-e PG_PRIMARY_HOST=${PRIMARY_CONTAINER_NAME} \
	-e SYNC_REPLICA=${SYNC_CONTAINER_NAME} \
	--link ${PRIMARY_CONTAINER_NAME}:${PRIMARY_CONTAINER_NAME} \
	-e PG_PRIMARY_PORT=5432 \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=${SYNC_CONTAINER_NAME} \
	--hostname=${SYNC_CONTAINER_NAME} \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG

echo "Starting the ${ASYNC_CONTAINER_NAME} container..."

sudo docker stop ${ASYNC_CONTAINER_NAME}
sudo docker rm ${ASYNC_CONTAINER_NAME}
docker volume rm ${ASYNC_CONTAINER_NAME}-pgdata

sudo docker run \
	-p 12012:5432 \
	-v ${ASYNC_CONTAINER_NAME}-pgdata:/pgdata \
	-e PGHOST=/tmp \
	-e TEMP_BUFFERS=9MB \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e WORK_MEM=5MB \
	-e PG_MODE=replica \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_PRIMARY_PASSWORD=password \
	-e PG_PRIMARY_HOST=${PRIMARY_CONTAINER_NAME} \
	--link ${PRIMARY_CONTAINER_NAME}:${PRIMARY_CONTAINER_NAME} \
	-e PG_PRIMARY_PORT=5432 \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=${ASYNC_CONTAINER_NAME} \
	--hostname=${ASYNC_CONTAINER_NAME} \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG
