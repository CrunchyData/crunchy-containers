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

source $CCPROOT/examples/envvars.sh

echo "This example depends on the primary-replica example being run prior!"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

sudo cp $DIR/config.yaml $PV_PATH/config.yaml

PROXY_IMAGE_TAG=centos7-1.0.0-beta

oc process -f $DIR/crunchy-proxy.json -p PROXY_IMAGE_TAG=$PROXY_IMAGE_TAG | oc create -f -
