#!/bin/bash

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

CONTAINER_NAME=restore

echo "Cleaning up..."

sudo docker stop "${CONTAINER_NAME}"
sudo docker rm "${CONTAINER_NAME}"
docker volume rm full-restore-pgdata

echo "Starting the pg_basebackup full restore example..."

docker run \
	--volume full-restore-pgdata:/pgdata \
	--volume backup-volume:/backup:ro \
	--env BACKUP_PATH=primary-backups/2020-02-08-21-07-31 \
	--env PGDATA_PATH=pgbasebackup-full-restored \
	--name="${CONTAINER_NAME}" \
	--hostname="${CONTAINER_NAME}" \
	--detach "${CCP_IMAGE_PREFIX}"/crunchy-pgbasebackup-restore:"${CCP_IMAGE_TAG}"
