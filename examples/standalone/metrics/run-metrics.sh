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

echo "stopping containers..."

docker stop crunchy-promgateway
docker rm crunchy-promgateway
docker stop crunchy-prometheus
docker rm crunchy-prometheus
docker stop crunchy-grafana
docker rm crunchy-grafana

DATA_DIR=/tmp/crunchy-metrics-data
sudo rm -rf $DATA_DIR
sudo mkdir -p $DATA_DIR
sudo chown daemon:daemon $DATA_DIR
sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR

export HOSTIP=`hostname --ip-address`
echo $HOSTIP

sudo docker run \
	-p $HOSTIP:9091:9091/tcp \
	-v $DATA_DIR:/data \
	--name=crunchy-promgateway \
	--hostname=crunchy-promgateway \
	-d crunchydata/crunchy-promgateway:$CCP_IMAGE_TAG

sudo docker run \
	-p $HOSTIP:19090:9090/tcp \
	-v $DATA_DIR:/data \
	--name=crunchy-prometheus \
	--hostname=crunchy-prometheus \
	--link crunchy-promgateway:crunchy-promgateway \
	-d crunchydata/crunchy-prometheus:$CCP_IMAGE_TAG


echo "sleeping 20 secs to give prometheus time to start up..."
sleep 20

sudo docker run \
	-p $HOSTIP:3000:3000/tcp \
	-v $DATA_DIR:/data \
	--link crunchy-prometheus:crunchy-prometheus \
	--name=crunchy-grafana \
	--hostname=crunchy-grafana \
	-d crunchydata/crunchy-grafana:$CCP_IMAGE_TAG
