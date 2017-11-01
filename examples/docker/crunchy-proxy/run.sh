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

echo "starting crunchy-proxy container...."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

CONTAINER_NAME=crunchyproxy
CONF_VOLUME=$CONTAINER_NAME-config

PROXY_IMAGE_TAG=centos7-1.0.0-beta

docker volume create --driver local --name=$CONF_VOLUME

docker run -it --privileged=true \
        --volume-driver=local \
        -v $DIR:/fromdir \
        -v $CONF_VOLUME:/config:z \
        --name=crunchyproxysetup \
	docker.io/centos:7 cp /fromdir/crunchy-proxy-config.yaml /config/config.yaml

docker rm -f crunchyproxysetup

docker run -it --privileged=true \
        --volume-driver=local \
        -v $DIR:/fromdir \
        -v $CONF_VOLUME:/config:z \
        --name=crunchyproxyls \
	docker.io/centos:7 ls /config

docker rm -f crunchyproxyls


docker run \
	-p 12432:5432 \
	-p 13001:10000 \
	-v $CONF_VOLUME:/config \
	--link primary:primary \
	--link replica:replica \
	--name=$CONTAINER_NAME \
	--hostname=$CONTAINER_NAME \
	-d crunchydata/crunchy-proxy:$PROXY_IMAGE_TAG
