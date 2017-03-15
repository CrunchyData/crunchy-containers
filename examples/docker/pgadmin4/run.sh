#!/bin/bash 

# Copyright 2016 Crunchy Data Solutions, Inc.
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

echo "stopping and removing pgadmin4 container..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONTAINER_NAME=pgadmin4
VOLUME_NAME=$CONTAINER_NAME-volume

DOCKER_NETWORK=${DOCKER_NETWORK:-"bridge"}

$DIR/cleanup.sh

docker volume create --driver local --name=$VOLUME_NAME

docker run \
	-p 5050:5050 \
	--network=$DOCKER_NETWORK
	--privileged=true \
	--volume-driver=local \
	-v $VOLUME_NAME:/pgdata:z \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d crunchydata/crunchy-pgadmin4:$CCP_IMAGE_TAG

