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

echo "Starting primary container..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

PRIMARY_SERVICE_NAME=primary

docker service create \
 --mount type=volume,src=$PRIMARY_SERVICE_NAME-volume,dst=/pgdata,volume-driver=local \
 --name $PRIMARY_SERVICE_NAME \
 --network crunchynet \
 --constraint 'node.labels.type == primary' \
 --env PGHOST=/tmp \
 --env PG_USER=testuser \
 --env PG_MODE=primary \
 --env PG_PRIMARY_USER=primaryuser \
 --env PG_ROOT_PASSWORD=password \
 --env PG_PASSWORD=password \
 --env PG_DATABASE=userdb \
 --env PG_PRIMARY_PORT=5432 \
 --env PG_PRIMARY_PASSWORD=password \
 $CCP_IMAGE_PREFIX/crunchy-postgres:centos7-9.5-1.2.8

echo "Sleep for a bit before starting the replica..."

sleep 30

SERVICE_NAME=replica
VOLUME_NAME=$SERVICE_NAME-volume


docker service create \
 --mount type=volume,src=$VOLUME_NAME,dst=/pgdata,volume-driver=local \
 --name $SERVICE_NAME \
 --network crunchynet \
 --constraint 'node.labels.type != primary' \
 --env PGHOST=/tmp \
 --env PG_USER=testuser \
 --env PG_MODE=replica \
 --env PG_PRIMARY_USER=primaryuser \
 --env PG_ROOT_PASSWORD=password \
 --env PG_PASSWORD=password \
 --env PG_DATABASE=userdb \
 --env PG_PRIMARY_PORT=5432 \
 --env PG_PRIMARY_PASSWORD=password \
 --env PG_PRIMARY_HOST=$PRIMARY_SERVICE_NAME \
 $CCP_IMAGE_PREFIX/crunchy-postgres:centos7-9.5-1.2.8
