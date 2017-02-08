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

sudo mkdir /nfsfileshare/pgconf /nfsfileshare/backrestrepo
sudo chown -R nfsnobody:nfsnobody  /nfsfileshare/pgconf /nfsfileshare/backrestrepo
sudo cp $DIR/pgbackrest.conf /nfsfileshare/pgconf

envsubst <  $DIR/backrestrepo-nfs-pv.json | oc create -f -

envsubst <  $DIR/pgconf-nfs-pv.json | oc create -f -

oc create -f $DIR/backrestrepo-nfs-pvc.json

oc create -f $DIR/pgconf-nfs-pvc.json

oc process -f $DIR/master-pod.json -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -

