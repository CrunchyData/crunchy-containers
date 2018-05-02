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

echo "Cleaning up..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONTAINER_NAME='custom-config'
PGDATA_VOL="${CONTAINER_NAME?}-pgdata"
PGWAL_VOL="${CONTAINER_NAME?}-wal"
BACKUP_VOL="${CONTAINER_NAME?}-backup"

docker stop ${CONTAINER_NAME?}
docker rm ${CONTAINER_NAME}
docker volume rm ${PGDATA_VOL?} ${PGWAL_VOL?} ${BACKUP_VOL?}
