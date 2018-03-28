#!/bin/bash

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

echo "starting backup container..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

CONTAINER_NAME=pgdump
VOLUME_NAME=$CONTAINER_NAME-volume
#
# this example assumes you have the basic example running
#
HOST_TO_BACKUP=basic

docker volume create --driver local --name=$VOLUME_NAME

docker run \
	--privileged=true \
	-v $VOLUME_NAME:/pgdata \
	-e PGDUMP_HOST=$HOST_TO_BACKUP \
	-e PGDUMP_DB=postgres \
	-e PGDUMP_USER=postgres\
	-e PGDUMP_PASS=password \
	-e PGDUMP_PORT=5432 \
	-e PGDUMP_LABEL=mybackup \
	-e PGDUMP_FORMAT=plain \
	-e PGDUMP_VERBOSE=true \
	-e PGDUMP_ALL=true \
	--link $HOST_TO_BACKUP:$HOST_TO_BACKUP\
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d $CCP_IMAGE_PREFIX/crunchy-pgdump:$CCP_IMAGE_TAG
