#!/bin/bash
set -u

# Copyright 2018 Crunchy Data Solutions, Inc.
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

CONTAINER_NAME=pgadmin4-https

echo "Starting the ${CONTAINER_NAME} example..."

mkdir $DIR/out

openssl req -x509 -newkey rsa:4096 -keyout $DIR/out/server.key \
    -out ${DIR}/out/server.crt \
    -days 5 -nodes -subj '/CN=localhost'

docker volume create --driver local --name=${CONTAINER_NAME}-data
docker volume create --driver local --name=${CONTAINER_NAME}-certs

docker run \
    --volume-driver=local \
    --name=$CONTAINER_NAME \
    --hostname=$CONTAINER_NAME \
    -p 5050:5050 \
    -v ${CONTAINER_NAME}-data:/var/lib/pgadmin:z\
    -v ${DIR?}/out:/certs:z \
    -e PGADMIN_SETUP_EMAIL='admin@admin.com' \
    -e PGADMIN_SETUP_PASSWORD='password' \
    -e SERVER_PORT='5050' \
    -e ENABLE_TLS='true' \
    -d ${CCP_IMAGE_PREFIX?}/crunchy-pgadmin4:${CCP_IMAGE_TAG?}
