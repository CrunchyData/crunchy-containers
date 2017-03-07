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

set -u

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$DIR"/cleanup.sh

CONTAINER_NAME=pgbouncer

# sudo chcon -Rt svirt_sandbox_file_t "$DIR"/conf

echo "starting pgbouncer container...."

docker run \
	-v "$DIR"/pgconf:/pgconf:Z \
	-p 12005:5432 \
	--privileged \
	-v /run/docker.sock:/run/docker.sock \
	-e FAILOVER=true \
	-e SLEEP_TIME=12 \
	-e PG_MASTER_SERVICE=master \
	-e PG_SLAVE_SERVICE=replica \
	-e PG_MASTER_PORT=5432 \
	-e PG_MASTER_USER=masteruser \
	-e PG_DATABASE=postgres \
	--link master:master \
	--link replica:replica \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d crunchydata/crunchy-pgbouncer:$CCP_IMAGE_TAG
