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

CONTAINER_NAME=backup

echo "Starting the ${CONTAINER_NAME} example..."

VOLUME_NAME=$CONTAINER_NAME-pgdata
BACKUP_HOST=primary

docker volume create --driver local --name=$VOLUME_NAME

docker run \
	--privileged=true \
	-v $VOLUME_NAME:/pgdata \
	-e BACKUP_HOST=$BACKUP_HOST \
	-e BACKUP_USER=primaryuser \
	-e BACKUP_PASS=password \
	-e BACKUP_PORT=5432 \
	-e BACKUP_LABEL=mybackup \
	--link $BACKUP_HOST:$BACKUP_HOST \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d $CCP_IMAGE_PREFIX/crunchy-backup:$CCP_IMAGE_TAG
