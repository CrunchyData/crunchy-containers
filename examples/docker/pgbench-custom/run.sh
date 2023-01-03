#!/bin/bash
set -u

# Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
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

docker run \
    --volume=${DIR?}/configs:/pgconf \
    -e PG_DATABASE=userdb \
    -e PG_HOSTNAME=primary \
    -e PG_PASSWORD=password \
    -e PG_PORT=5432 \
    -e PG_USERNAME=testuser \
    --name=pgbench-custom \
    --hostname=pgbench-custom \
    --network=pgnet \
    -d $CCP_IMAGE_PREFIX/crunchy-pgbench:$CCP_IMAGE_TAG
