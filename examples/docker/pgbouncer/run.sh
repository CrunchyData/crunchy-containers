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

echo "starting pgbouncer container...."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$DIR"/cleanup.sh

CONTAINER_NAME=pgbouncer

sudo chcon -Rt svirt_sandbox_file_t "$DIR"

sudo docker run \
	-v "$DIR":/pgconf \
	-p 12005:5432 \
	--privileged \
	-e PG_PRIMARY_SERVICE=primary \
	-e PG_REPLICA_SERVICE=replica \
	-e PG_PRIMARY_PORT=5432 \
	-e PG_PRIMARY_USER=primaryuser \
	-e PG_DATABASE=postgres \
	--link primary:primary \
	--link replica:replica \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d ${CCP_IMAGE_PREFIX}/crunchy-pgbouncer:$CCP_IMAGE_TAG
