#!/bin/bash 

# Copyright 2017 Crunchy Data Solutions, Inc.
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

echo "starting setupsql container..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

CONTAINER=setupsql
CONF_VOLUME=$CONTAINER-pgconf
DATA_VOLUME=$CONTAINER-volume
WAL_VOLUME=$CONTAINER-wal

docker volume create --driver local --name=$CONF_VOLUME
docker volume create --driver local --name=$DATA_VOLUME
docker volume create --driver local --name=$WAL_VOLUME

docker run -it --privileged=true \
	--volume-driver=local \
	-v $DIR:/fromdir \
	-v $CONF_VOLUME:/pgconf:z \
	--name=$CONTAINER-setup \
	crunchydata/crunchy-postgres:$CCP_IMAGE_TAG cp /fromdir/setup.sql /pgconf
docker run -it --privileged=true \
	--volume-driver=local \
	-v $CONF_VOLUME:/pgconf:z \
	--name=$CONTAINER-ls \
	crunchydata/crunchy-postgres:$CCP_IMAGE_TAG ls /pgconf

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
	-e PG_MODE=master \
	-e PG_MASTER_USER=masteruser \
	-e PG_MASTER_PASSWORD=password \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=$CONTAINER \
	--hostname=$CONTAINER \
	-d crunchydata/crunchy-postgres:$CCP_IMAGE_TAG

