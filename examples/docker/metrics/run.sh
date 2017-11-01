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

echo "starting metrics example.."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$DIR/cleanup.sh

#export HOSTIP=`hostname --ip-address`
export HOSTIP=127.0.0.1
echo $HOSTIP

VOLUME_NAME=metrics-volume
docker volume create --driver local --name=$VOLUME_NAME

docker run \
	-p $HOSTIP:19091:9091/tcp \
	--name=crunchy-promgateway \
	--hostname=crunchy-promgateway \
	-d crunchydata/crunchy-promgateway:$CCP_IMAGE_TAG

echo "sleep a bit since we are linking to crunchy-promgateway..."
sleep 10

docker run \
	-p $HOSTIP:19090:9090/tcp \
	--privileged=true \
	--volume-driver=local \
	-v $VOLUME_NAME:/data:z \
	--name=crunchy-prometheus \
	--hostname=crunchy-prometheus \
	--link crunchy-promgateway:crunchy-metrics \
	-d crunchydata/crunchy-prometheus:$CCP_IMAGE_TAG

echo "sleep a bit since we are linking to crunchy-prometheus..."
sleep 10

docker run \
	-p $HOSTIP:13000:3000/tcp \
	--privileged=true \
	--volume-driver=local \
	-v $VOLUME_NAME:/data:z \
	--link crunchy-prometheus:crunchy-prometheus \
	--name=crunchy-grafana \
	--hostname=crunchy-grafana \
	-d crunchydata/crunchy-grafana:$CCP_IMAGE_TAG
