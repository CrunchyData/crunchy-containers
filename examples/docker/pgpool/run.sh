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

CONTAINER_NAME=pgpool

echo "Starting the ${CONTAINER_NAME} example..."

docker run \
	-p 12003:5432 \
	--link primary:primary \
	--link replica:replica \
	-e PG_PRIMARY_SERVICE_NAME=primary \
	-e PG_REPLICA_SERVICE_NAME=replica \
	-e PG_USERNAME=testuser \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=postgres \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d $CCP_IMAGE_PREFIX/crunchy-pgpool:$CCP_IMAGE_TAG
