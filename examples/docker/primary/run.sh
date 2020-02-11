#!/bin/bash
set -u

# Copyright 2016 - 2020 Crunchy Data Solutions, Inc.
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

docker network create --driver bridge pgnet
docker volume create --driver local --name=primary-pgdata

docker run \
    -p 5432:5432 \
    -v primary-pgdata:/pgdata \
    -e PG_MODE=primary \
    -e PG_USER=testuser \
    -e PG_PASSWORD=password \
    -e PG_DATABASE=userdb \
    -e PG_PRIMARY_USER=primaryuser \
    -e PG_PRIMARY_PORT=5432 \
    -e PG_PRIMARY_PASSWORD=password \
    -e PG_ROOT_PASSWORD=password \
    -e PGHOST=/tmp \
    --name=primary \
    --hostname=primary \
    --network=pgnet \
    -d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG
