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

echo "starting primary container..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

CONTAINER=backrest
PGCONF_VOLUME_NAME=$CONTAINER-pgconf

docker volume create --driver local --name=$PGCONF_VOLUME_NAME

docker run -it --privileged=true \
	--volume-driver=local \
	-v $DIR:/fromdir \
	-v $PGCONF_VOLUME_NAME:/pgconf:z \
	--name=backrest-setup \
	crunchydata/crunchy-postgres:$CCP_IMAGE_TAG cp /fromdir/pgbackrest.conf /pgconf

docker run -it --privileged=true \
	--volume-driver=local \
	-v $PGCONF_VOLUME_NAME:/pgconf:z \
	--name=backrest-ls \
	crunchydata/crunchy-postgres:$CCP_IMAGE_TAG ls /pgconf

# the backrest repo that backrest will write to
REPO_VOLUME_NAME=$CONTAINER-backrestrepo

docker volume create --driver local --name=$REPO_VOLUME_NAME

DATA_VOLUME_NAME=$CONTAINER-pgdata
docker volume create --driver local --name=$DATA_VOLUME_NAME

docker run \
	-p 12000:5432 \
	--privileged=true \
	--volume-driver=local \
	-v $REPO_VOLUME_NAME:/backrestrepo:z \
	-v $PGCONF_VOLUME_NAME:/pgconf:z \
	-v $DATA_VOLUME_NAME:/pgdata:z \
	-e ARCHIVE_TIMEOUT=60 \
	-e TEMP_BUFFERS=9MB \
	-e PGHOST=/tmp \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e WORK_MEM=5MB \
	-e PG_MODE=primary \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_PRIMARY_PASSWORD=password \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=$CONTAINER \
	--hostname=$CONTAINER \
	-d crunchydata/crunchy-postgres:$CCP_IMAGE_TAG
