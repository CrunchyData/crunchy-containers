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

source $BUILDBASE/examples/envvars.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh
DATADIR=/nfsfileshare/pgadmin4

if [ ! -d "$DATADIR" ]; then
	echo "setting up pg4admin data directory...."
	sudo mkdir $DATADIR
	sudo cp $BUILDBASE/conf/pgadmin4/config_local.py $DATADIR
	sudo cp $BUILDBASE/conf/pgadmin4/pgadmin4.db $DATADIR
	sudo chmod -R 777 $DATADIR
fi

envsubst <  $DIR/pgadmin4-nfs-pv.json | kubectl create -f -

kubectl create -f $DIR/pgadmin4-nfs-pvc.json

kubectl create -f $DIR/pgadmin4-service.json
envsubst < $DIR/pgadmin4-pod.json | kubectl create -f -
