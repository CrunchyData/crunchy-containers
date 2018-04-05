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

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$DIR"/cleanup.sh

CONTAINER_NAME=pgbouncer
PRIMARY_CONTAINER_NAME=pg-primary
REPLICA_CONTAINER_NAME=pg-replica

echo "Starting the ${CONTAINER_NAME} example..."

sudo chcon -Rt svirt_sandbox_file_t "$DIR"

echo "Starting the ${PRIMARY_CONTAINER_NAME} container..."

PRIMARY_VOLUME_NAME=${PRIMARY_CONTAINER_NAME}-pgdata
docker volume create --driver local --name=$PRIMARY_VOLUME_NAME

docker run \
	-p 12007:5432 \
	--privileged=true \
	-v $PRIMARY_VOLUME_NAME:/pgdata \
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
	--name=${PRIMARY_CONTAINER_NAME} \
	--hostname=${PRIMARY_CONTAINER_NAME} \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG

echo "Starting the ${REPLICA_CONTAINER_NAME} container..."

sleep 20

REPLICA_VOLUME_NAME=${REPLICA_CONTAINER_NAME}-pgdata
docker volume create --driver local --name=$REPLICA_VOLUME_NAME

docker run \
	-p 12008:5432 \
	--privileged=true \
	-v $REPLICA_VOLUME_NAME:/pgdata \
	-e TEMP_BUFFERS=9MB \
	-e PG_PRIMARY_HOST=${PRIMARY_CONTAINER_NAME} \
	-e PGHOST=/tmp \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e WORK_MEM=5MB \
	-e PG_MODE=replica \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_PRIMARY_PASSWORD=password \
	--link ${PRIMARY_CONTAINER_NAME}:${PRIMARY_CONTAINER_NAME} \
	-e PG_PRIMARY_PORT=5432 \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=${REPLICA_CONTAINER_NAME} \
	--hostname=${REPLICA_CONTAINER_NAME} \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG

echo "Starting the ${CONTAINER_NAME} container..."

sleep 20

sudo docker run \
	-v "$DIR":/pgconf \
	-p 6543:6543 \
	--privileged \
	--link ${PRIMARY_CONTAINER_NAME}:${PRIMARY_CONTAINER_NAME} \
	--link ${REPLICA_CONTAINER_NAME}:${REPLICA_CONTAINER_NAME} \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d ${CCP_IMAGE_PREFIX}/crunchy-pgbouncer:$CCP_IMAGE_TAG
