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

source $CCPROOT/examples/envvars.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

CONFIGDIR=$NFS_PATH/bouncerconfig
sudo rm -rf $CONFIGDIR
sudo mkdir $CONFIGDIR
sudo chmod 777 $CONFIGDIR

sudo cp $DIR/pgbouncer.ini $CONFIGDIR
sudo cp $DIR/users.txt $CONFIGDIR

kubectl create -f $DIR/pgbouncer-service.json
envsubst < $DIR/pgbouncer.json | kubectl create -f -
