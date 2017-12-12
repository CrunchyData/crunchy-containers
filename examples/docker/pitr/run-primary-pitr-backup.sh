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

echo "Starting primary-pitr-backup container..."

PGDATA=/tmp/backups

if [ ! -d "$PGDATA" ]; then
	echo "Creating pgdata directory..."
	mkdir -p $PGDATA
fi

sudo chown postgres:postgres $PGDATA
sudo chcon -Rt svirt_sandbox_file_t $PGDATA

docker stop primary-pitr-backup
docker rm primary-pitr-backup

docker run \
	-v $PGDATA:/pgdata \
	-e BACKUP_HOST=primary-pitr \
	-e BACKUP_USER=primaryuser \
	-e BACKUP_PASS=password \
	-e BACKUP_PORT=5432 \
	-e BACKUP_LABEL=mybackup1 \
	--link primary-pitr:primary-pitr\
	--name=primary-pitr-backup \
	--hostname=primary-pitr-backup \
	-d $CCP_IMAGE_PREFIX/crunchy-backup:$CCP_IMAGE_TAG
