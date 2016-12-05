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

echo "starting master container..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# uncomment these lines to override the pg config files with
# your own versions of pg_hba.conf and postgresql.conf
PGCONF=/tmp/backtestdb-pgconf
sudo rm -rf $PGCONF
sudo mkdir $PGCONF
sudo chmod 0700 $PGCONF
sudo chcon -Rt svirt_sandbox_file_t $PGCONF
sudo cp pgbackrest.conf $PGCONF
sudo chown -R postgres:postgres $PGCONF

# the backrest repo that backrest will write to
BACKRESTREPO=/tmp/backtestdb-backrestrepo
sudo rm -rf $BACKRESTREPO
sudo mkdir $BACKRESTREPO
sudo chmod 0700 $BACKRESTREPO
sudo chcon -Rt svirt_sandbox_file_t $BACKRESTREPO
sudo chown postgres:postgres $BACKRESTREPO

# add this next line to the docker run to override pg config files

DATA_DIR=/tmp/backtestdb-data
sudo rm -rf $DATA_DIR
sudo mkdir -p $DATA_DIR
sudo chown postgres:postgres $DATA_DIR
sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR

CONTAINER=backtestdb
docker stop $CONTAINER
docker rm $CONTAINER

docker run \
	-p 12000:5432 \
	-v $BACKRESTREPO:/backrestrepo \
	-v $PGCONF:/pgconf \
	-v $DATA_DIR:/pgdata \
	-e ARCHIVE_TIMEOUT=60 \
	-e TEMP_BUFFERS=9MB \
	-e PGHOST=/tmp \
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
	--name=$CONTAINER \
	--hostname=$CONTAINER \
	-d crunchydata/crunchy-postgres:$CCP_IMAGE_TAG

