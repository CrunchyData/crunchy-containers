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

export CONTAINER_NAME=restore

echo "Starting the ${CONTAINER_NAME} example..."

# $1=date-named directory, e.g. 2017-01-12-17-43-08
export BACKUP_PATH=primary-backups/$1

export CONTAINER_VOLUME=$CONTAINER_NAME-pgdata

# uncomment these lines to override the pg config files with
# your own versions of pg_hba.conf and postgresql.conf
#PGCONF=$HOME/openshift-dedicated-container/pgconf
#sudo chown postgres:postgres $PGCONF
#sudo chmod 0700 $PGCONF
#sudo chcon -Rt svirt_sandbox_file_t $PGCONF
# add this next line to the docker run to override pg config files

docker volume create --driver local --name=$CONTAINER_VOLUME
BACKUP_VOLUME=backup-volume

docker run \
	-p 12001:5432 \
	--privileged=true \
	-v $CONTAINER_VOLUME:/pgdata:z \
	-v $BACKUP_VOLUME:/backup:ro \
	-e BACKUP_PATH=$BACKUP_PATH \
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
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG
