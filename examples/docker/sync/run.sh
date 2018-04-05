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

echo "Starting the sync example..."

PRIMARY_CONTAINER_NAME=primarysync
SYNC_CONTAINER_NAME=replicasync
ASYNC_CONTAINER_NAME=replicaasync

echo "Starting the ${PRIMARY_CONTAINER_NAME} container..."

# uncomment these lines to override the pg config files with
# your own versions of pg_hba.conf and postgresql.conf
#PGCONF=$HOME/openshift-dedicated-container/pgconf
#sudo chown postgres:postgres $PGCONF
#sudo chmod 0700 $PGCONF
#sudo chcon -Rt svirt_sandbox_file_t $PGCONF
# add this next line to the docker run to override pg config files

DATA_DIR=/tmp/${PRIMARY_CONTAINER_NAME}-data
sudo rm -rf $DATA_DIR
sudo mkdir -p $DATA_DIR
sudo chown postgres:postgres $DATA_DIR
sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR

sudo docker stop ${PRIMARY_CONTAINER_NAME}
sudo docker rm ${PRIMARY_CONTAINER_NAME}

sudo docker run \
	-p 12010:5432 \
	-v $DATA_DIR:/pgdata \
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

DATA_DIR=/tmp/${SYNC_CONTAINER_NAME}
sudo rm -rf $DATA_DIR
sudo mkdir -p $DATA_DIR
sudo chown postgres:postgres $DATA_DIR
sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR

sudo docker stop ${SYNC_CONTAINER_NAME}
sudo docker rm ${SYNC_CONTAINER_NAME}

sudo docker run \
	-p 12011:5432 \
	-v $DATA_DIR:/pgdata \
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

DATA_DIR=/tmp/${ASYNC_CONTAINER_NAME}
sudo rm -rf $DATA_DIR
sudo mkdir -p $DATA_DIR
sudo chown postgres:postgres $DATA_DIR
sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR

sudo docker stop ${ASYNC_CONTAINER_NAME}
sudo docker rm ${ASYNC_CONTAINER_NAME}

sudo docker run \
	-p 12012:5432 \
	-v $DATA_DIR:/pgdata \
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
