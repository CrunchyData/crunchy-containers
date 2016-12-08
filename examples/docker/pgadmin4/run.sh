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

echo "stopping and removing pgadmin4 container..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONTAINER_NAME=pgadmin4
VOLUME_NAME=$CONTAINER_NAME-volume

$DIR/cleanup.sh

docker volume create --driver local --name=$VOLUME_NAME

#echo "setting up pgadmin4 data directory..."
#DATA_DIR=/tmp/pgadmin4-data
#if [ ! -d "$DATA_DIR" ]; then
#	echo "setting up local data directory..."
#	sudo mkdir -p $DATA_DIR
#	sudo chown root:root $DATA_DIR
#	sudo chmod 777 $DATA_DIR
#	sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR
#	sudo cp $BUILDBASE/conf/pgadmin4/config_local.py $DATA_DIR
#	sudo cp $BUILDBASE/conf/pgadmin4/pgadmin4.db $DATA_DIR
#fi

docker run \
	-p 5050:5050 \
	--privileged=true \
	--volume-driver=local \
	-v $VOLUME_NAME:/root/.pgadmin:z \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d crunchydata/crunchy-pgadmin4:$CCP_IMAGE_TAG

