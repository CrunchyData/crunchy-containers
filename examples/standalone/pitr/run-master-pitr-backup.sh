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

echo "starting master-pitr-backup container..."

PGDATA=/tmp/backups

if [ ! -d "$PGDATA" ]; then
	echo "creating pgdata directory..."
	mkdir -p $PGDATA
fi

sudo chown postgres:postgres $PGDATA
sudo chcon -Rt svirt_sandbox_file_t $PGDATA

docker stop master-pitr-backup
docker rm master-pitr-backup

docker run \
	-v $PGDATA:/pgdata \
	-e BACKUP_HOST=master-pitr \
	-e BACKUP_USER=masteruser \
	-e BACKUP_PASS=password \
	-e BACKUP_PORT=5432 \
	-e BACKUP_LABEL=mybackup1 \
	--link master-pitr:master-pitr\
	--name=master-pitr-backup \
	--hostname=master-pitr-backup \
	-d crunchydata/crunchy-backup:$CCP_IMAGE_TAG

