#!/bin/bash

# Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
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

$DIR/cleanup.sh

echo "Starting the primary-replica example..."

PRIMARY_CONTAINER_NAME=primary

echo "Starting the ${PRIMARY_CONTAINER_NAME} container..."

# uncomment these lines to override the pg config files with
# your own versions of pg_hba.conf and postgresql.conf
#PGCONF=$HOME/openshift-dedicated-container/pgconf
#sudo chown postgres:postgres $PGCONF
#sudo chmod 0700 $PGCONF
#sudo chcon -Rt svirt_sandbox_file_t $PGCONF
# add this next line to the docker run to override pg config files
#DATA_DIR=/tmp/primary-data
#sudo rm -rf $DATA_DIR
#sudo mkdir -p $DATA_DIR
#sudo chown postgres:postgres $DATA_DIR
#sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR
#DATA_DIR=/tmp/pg-replica-data
#sudo rm -rf $DATA_DIR
#sudo mkdir -p $DATA_DIR
#sudo chown postgres:postgres $DATA_DIR
#sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR

PRIMARY_VOLUME_NAME=${PRIMARY_CONTAINER_NAME}-pgdata
docker volume create --driver local --name=${PRIMARY_VOLUME_NAME}

docker run \
	-p 12007:5432 \
	--privileged=true \
	-v ${PRIMARY_VOLUME_NAME}:/pgdata \
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
	--name=$PRIMARY_CONTAINER_NAME \
	--hostname=$PRIMARY_CONTAINER_NAME \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG

REPLICA_CONTAINER_NAME=replica

echo "Starting the ${REPLICA_CONTAINER_NAME} container..."

sleep 20

REPLICA_VOLUME_NAME=${REPLICA_CONTAINER_NAME}-pgdata
docker volume create --driver local --name=${REPLICA_VOLUME_NAME}

docker run \
	-p 12008:5432 \
	--privileged=true \
	-v ${REPLICA_VOLUME_NAME}:/pgdata \
	-e TEMP_BUFFERS=9MB \
	-e PG_PRIMARY_HOST=$PRIMARY_CONTAINER_NAME \
	-e PGHOST=/tmp \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e WORK_MEM=5MB \
	-e PG_MODE=replica \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_PRIMARY_PASSWORD=password \
	--link $PRIMARY_CONTAINER_NAME:$PRIMARY_CONTAINER_NAME \
	-e PG_PRIMARY_PORT=5432 \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=${REPLICA_CONTAINER_NAME} \
	--hostname=${REPLICA_CONTAINER_NAME} \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG
