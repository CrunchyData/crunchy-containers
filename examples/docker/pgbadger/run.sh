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
${DIR?}/cleanup.sh

docker network create --driver bridge pgnet

docker run \
    -p 5432:5432 \
    -v pg-primary:/pgdata \
    --network=pgnet \
    --env-file=${DIR?}/env/pgsql-primary.list \
    --name=pg-primary \
    --hostname=pg-primary \
    -d ${CCP_IMAGE_PREFIX?}/crunchy-postgres:${CCP_IMAGE_TAG?}

docker run \
    -p 10000:10000 \
    -v pg-primary:/pgdata:ro \
    -v report:/report \
    --env=BADGER_TARGET='pg-primary' \
    --env=BADGER_CUSTOM_OPTS='--incremental' \
    --network=pgnet \
    --name='pgbadger' \
    --hostname='pgbadger' \
    -d ${CCP_IMAGE_PREFIX?}/crunchy-pgbadger:${CCP_IMAGE_TAG?}

exit 0
