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

$DIR/cleanup.sh

CONTAINER_NAME=custom-config

echo "Starting the ${CONTAINER_NAME} example..."

CONF_VOLUME=${CONTAINER_NAME}-pgconf
DATA_VOLUME=${CONTAINER_NAME}-pgdata
WAL_VOLUME=${CONTAINER_NAME}-wal

docker volume create --driver local --name=$CONF_VOLUME
docker volume create --driver local --name=$DATA_VOLUME
docker volume create --driver local --name=$WAL_VOLUME

docker run -it --privileged=true \
	--volume-driver=local \
	-v $DIR:/fromdir \
	-v $CONF_VOLUME:/pgconf:z \
	--name=${CONTAINER_NAME}-setup \
	$CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG cp /fromdir/setup.sql /pgconf
docker run -it --privileged=true \
	--volume-driver=local \
	-v $CONF_VOLUME:/pgconf:z \
	--name=${CONTAINER_NAME}-ls \
	$CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG ls /pgconf

docker run \
	-p 12009:5432 \
	-v $CONF_VOLUME:/pgconf:z \
	-v $DATA_VOLUME:/pgdata:z \
	-v $WAL_VOLUME:/pgwal:rw \
	-e TEMP_BUFFERS=9MB \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e XLOGDIR=/pgwal \
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
