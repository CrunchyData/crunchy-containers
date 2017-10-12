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

echo "starting badger..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

CONTAINER_NAME=badger
DATABASE_CONTAINER=basic
VOLUME_NAME=basic-example-volume

docker run \
	-p 14000:10000 \
	--privileged=true \
	--volume-driver=local \
	-v $VOLUME_NAME:/pgdata:ro \
	-e BADGER_TARGET=$DATABASE_CONTAINER \
	--link $DATABASE_CONTAINER:$DATABASE_CONTAINER \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d crunchydata/crunchy-pgbadger:$CCP_IMAGE_TAG
