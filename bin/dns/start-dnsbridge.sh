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

# consul configuration params
if [ ! -v DC ]; then
	echo "DC env var is not set, using default value of [dc1]"
	export DC=dc1
fi
if [ ! -v DOMAIN ]; then
	echo "DOMAIN env var is not set, using default value of [consul.]"
	export DOMAIN="consul."
fi
if [ ! -v DOCKER_URL ]; then
	echo "DOCKER_URL env var is not set, using default value of [unix:///tmp/docker.sock]"
	export DOCKER_URL="unix:///tmp/docker.sock"
fi


export DC=$DC
export DOMAIN=$DOMAIN

HOSTIP=`ip addr show eth0 | grep " inet " | xargs  | cut -f2 -d' ' | cut -f1 -d'/'`
echo "host ip is " $HOSTIP
export CONSUL_URL=http://$HOSTIP:8500

/opt/cpm/bin/consul agent -ui -server=true -bootstrap=true -data-dir=/consuldata -pid-file=/consuldata/consul.pid -client=$HOSTIP -dc=$DC -domain=$DOMAIN &

/opt/cpm/bin/dnsbridgeserver
