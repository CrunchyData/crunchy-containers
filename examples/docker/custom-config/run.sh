#!/bin/bash

# Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
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
CONTAINER_NAME='custom-config'
PGDATA_VOL="${CONTAINER_NAME?}-pgdata"
PGWAL_VOL="${CONTAINER_NAME?}-wal"
BACKUP_VOL="${CONTAINER_NAME?}-backup"

${DIR?}/cleanup.sh

echo "Starting the ${CONTAINER_NAME} example..."

docker volume create --driver local --name=${PGDATA_VOL?}
docker volume create --driver local --name=${PGWAL_VOL?}
docker volume create --driver local --name=${BACKUP_VOL?}

docker run \
    --name=${CONTAINER_NAME?} \
    --hostname=${CONTAINER_NAME?} \
    --publish=5432:5432 \
    --volume=${DIR?}/configs:/pgconf \
    --volume=${PGDATA_VOL?}:/pgdata \
    --volume=${PGWAL_VOL?}:/pgwal \
    --volume=${BACKUP_VOL?}:/backrestrepo \
    --env=PG_MODE=primary \
    --env=PG_PRIMARY_USER=primaryuser \
    --env=PG_PRIMARY_PASSWORD=password \
    --env=PG_PRIMARY_HOST=localhost \
    --env=PG_PRIMARY_PORT=5432 \
    --env=PG_DATABASE=userdb \
    --env=PG_USER=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_ROOT_PASSWORD=password \
    --env=PGHOST=/tmp \
    --env=XLOGDIR=true \
    --env=PGBACKREST=true \
    --detach ${CCP_IMAGE_PREFIX?}/crunchy-postgres:${CCP_IMAGE_TAG?}
