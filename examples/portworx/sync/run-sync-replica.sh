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

echo "starting sync-replica container..."
$CCPROOT/examples/envvars.sh

sudo docker stop sync-replica
sudo docker rm sync-replica

sudo docker run \
	--security-opt=label:disable \
	-p $LOCAL_IP:12012:5432 \
	-v sync-slave-volume:/pgdata \
	-e PG_MODE=slave \
	-e PG_MASTER_USER=masteruser \
	-e PG_MASTER_PASSWORD=password \
	-e PG_MASTER_HOST=sync-master \
	-e SYNC_SLAVE=sync-slave \
	--link sync-master:sync-master \
	-e PG_MASTER_PORT=5432 \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=sync-replica \
	--hostname=sync-replica \
	-d crunchydata/crunchy-postgres:$CCP_IMAGE_TAG
