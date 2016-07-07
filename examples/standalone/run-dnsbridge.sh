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

echo "starting dnsbridge container..."

docker stop crunchy-dns
docker rm crunchy-dns

DATA_DIR=/tmp/crunchy-dns
sudo rm -rf $DATA_DIR
sudo mkdir -p $DATA_DIR
sudo chown postgres:postgres $DATA_DIR
sudo chcon -Rt svirt_sandbox_file_t $DATA_DIR

export HOSTIP=`hostname --ip-address`

sudo docker run \
	-p $HOSTIP:8500:8500/tcp \
	-p $HOSTIP:53:8600/udp \
	-v $DATA_DIR:/consuldata \
	--privileged \
	-v /run/docker.sock:/tmp/docker.sock \
	-e DOCKER_URL=unix:///tmp/docker.sock \
	-e DC=dc1 \
	-e DOMAIN=crunchy.lab. \
	--name=crunchy-dns \
	--hostname=crunchy-dns \
	-d crunchydata/crunchy-dns:centos7-9.5-$CCP_VERSION

