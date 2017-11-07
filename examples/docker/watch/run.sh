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

echo "starting crunchy-watch container"

export CONTAINER_NAME=watch
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$DIR/cleanup.sh

#
# make sure the docker socket has permissions that allow
# the postgres user to read it or else this example will not
# be able to read and write to mounted docker socket
#
sudo docker run \
	--privileged \
	-v /run/docker.sock:/run/docker.sock \
	--link primary:primary \
	--link replica:replica \
	-e PG_PRIMARY_SERVICE=primary \
	-e PG_REPLICA_SERVICE=replica \
	-e PG_PRIMARY_PORT=5432 \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_DATABASE=postgres \
	-e SLEEP_TIME=20 \
	-e WATCH_PRE_HOOK="/hooks/watch-pre-hook" \
	-e WATCH_POST_HOOK="/hooks/watch-post-hook" \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-v $PWD/hooks:/hooks \
	-d crunchydata/crunchy-watch:$CCP_IMAGE_TAG
