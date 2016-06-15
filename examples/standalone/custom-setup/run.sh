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

echo "starting setupsql container..."


CONF_DIR=/tmp/setupsql-conf
DATA_DIR=/tmp/setupsql-data

sudo rm -rf $DATA_DIR $CONF_DIR
sudo mkdir -p $DATA_DIR $CONF_DIR

sudo cp `pwd`/setup.sql $CONF_DIR

sudo chown postgres:postgres $DATA_DIR $CONF_DIR

sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR $CONF_DIR

sudo chmod 0700 $CONF_DIR

sudo docker stop setupsql
sudo docker rm setupsql

sudo docker run \
	-p 12000:5432 \
	-v $CONF_DIR:/pgconf \
	-v $DATA_DIR:/pgdata \
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
	--name=setupsql \
	--hostname=setupsql \
	-d crunchydata/crunchy-postgres:latest

