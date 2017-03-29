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

echo "starting restoredmaster container..."

$CCPROOT/examples/envvars.sh

BACKUP_PATH=master/2016-07-12-19-36-30

docker run \
	--security-opt=label:disable \
        -p $LOCAL_IP:12002:5432 \
        -v restoredmaster-volume:/pgdata \
        -v backup-volume:/backup \
        -e BACKUP_PATH=$BACKUP_PATH \
        -e TEMP_BUFFERS=9MB \
        -e MAX_CONNECTIONS=101 \
        -e SHARED_BUFFERS=129MB \
        -e MAX_WAL_SENDERS=7 \
        -e WORK_MEM=5MB \
        -e PG_MODE=master \
        -e PG_MASTER_USER=masteruser \
        -e PG_MASTER_PASSWORD=password \
        -e PG_USER=testuser \
        -e PG_ROOT_PASSWORD=password \
        -e PG_PASSWORD=password \
        -e PG_DATABASE=userdb \
        --name=restoredmaster \
        --hostname=restoredmaster \
        -d crunchydata/crunchy-postgres:$CCP_IMAGE_TAG


