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

CONTAINER_NAME=postgres-sshd

echo "Starting the ${CONTAINER_NAME} example..."

mkdir -p ${DIR?}/keys
ssh-keygen -f ${DIR?}/keys/id_rsa -t rsa -N ''
ssh-keygen -t rsa -f ${DIR?}/keys/ssh_host_rsa_key -N ''
ssh-keygen -t ecdsa -f ${DIR?}/keys/ssh_host_ecdsa_key -N ''
ssh-keygen -t ed25519 -f ${DIR?}/keys/ssh_host_ed25519_key -N ''
cp ${DIR?}/keys/id_rsa.pub ${DIR?}/config/authorized_keys

docker volume create --driver local --name=${CONTAINER_NAME?}-pgdata
docker volume create --driver local --name=${CONTAINER_NAME?}-backrestrepo

docker run \
    --volume-driver=local \
    --env-file=${DIR?}/env.list \
    --name=$CONTAINER_NAME \
    --hostname=$CONTAINER_NAME \
    -p 5432:5432 \
    -p 2022:2022 \
    -v ${CONTAINER_NAME?}-pgdata:/pgdata:z\
    -v ${CONTAINER_NAME?}-backrestrepo:/backrestrepo:z \
    -v ${DIR?}/config:/pgconf \
    -v ${DIR?}/keys:/sshd \
    -d ${CCP_IMAGE_PREFIX?}/crunchy-postgres:${CCP_IMAGE_TAG?}
