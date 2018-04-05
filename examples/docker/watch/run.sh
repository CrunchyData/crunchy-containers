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

export CONTAINER_NAME=watch

echo "Starting the ${CONTAINER_NAME} example..."
#
# Make sure the Docker socket has permissions that allow
# the postgres user to read it, or else this example will not
# be able to read and write to the mounted Docker socket.
#
sudo docker run \
	--privileged \
	-v /run/docker.sock:/run/docker.sock \
	--link primary:primary \
	--link replica:replica \
	-e CRUNCHY_WATCH_PRIMARY=primary \
	-e CRUNCHY_WATCH_REPLICA=replica \
	-e CRUNCHY_WATCH_PRIMARY_PORT=5432 \
	-e CRUNCHY_WATCH_USERNAME=primaryuser \
	-e CRUNCHY_WATCH_DATABASE=postgres \
	-e CRUNCHY_WATCH_HEALTHCHECK_INTERVAL=20 \
	-e CRUNCHY_WATCH_FAILOVER_WAIT=10s \
	-e CRUNCHY_WATCH_PRE_HOOK="/hooks/watch-pre-hook" \
	-e CRUNCHY_WATCH_POST_HOOK="/hooks/watch-post-hook" \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-v $PWD/hooks:/hooks \
	-d $CCP_IMAGE_PREFIX/crunchy-watch:$CCP_IMAGE_TAG
