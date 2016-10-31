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

DATA_DIR=/tmp/backtestdb-data

CONF_DIR=/tmp/backrestd-conf
sudo rm -rf $CONF_DIR
sudo mkdir -p $CONF_DIR
sudo chcon -Rt svirt_sandbox_file_t $CONF_DIR
sudo cp ./sshd-config/sshd_config $CONF_DIR
sudo cp ./pgbackrest.conf $CONF_DIR
sudo chown -R postgres:postgres $CONF_DIR

KEYS=/tmp/backrestd-keys
sudo rm -rf $KEYS
sudo mkdir -p $KEYS
sudo chcon -Rt svirt_sandbox_file_t $KEYS
sudo cp ./sshd-keys/ssh_host_dsa_key $KEYS
sudo cp ./sshd-keys/ssh_host_ecdsa_key $KEYS
sudo cp ./sshd-keys/ssh_host_rsa_key $KEYS
sudo cp ./sshd-keys/authorized_keys $KEYS
sudo chown -R postgres:postgres $KEYS

# the backrest repo that backrest will write to
BACKRESTREPO=/tmp/backtestdb-backrestrepo

CONTAINER=backrestd
echo "starting " $CONTAINER " container..."
sudo docker stop $CONTAINER
sudo docker rm $CONTAINER

sudo docker run \
	-v $BACKRESTREPO:/backrestrepo \
	-v $CONF_DIR:/pgconf \
	-v $DATA_DIR:/pgdata \
	-v $KEYS:/keys \
	-e TEMP_BUFFERS=9MB \
	-e PGHOST=/tmp \
	-e MAX_CONNECTIONS=101 \
	-e SHARED_BUFFERS=129MB \
	-e MAX_WAL_SENDERS=7 \
	-e WORK_MEM=5MB \
	-e PG_MASTER_USER=masteruser \
	-e PG_MASTER_PASSWORD=password \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--link backtestdb:backtestdb\
	--name=$CONTAINER \
	--hostname=$CONTAINER \
	-d crunchydata/crunchy-backrestd:$CCP_IMAGE_TAG

