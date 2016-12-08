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

# set up the NFS claim to store the WAL into
envsubst < $DIR/master-pitr-wal-pv.json |  oc create -f -

# set up the NFS claim to store the pgdata into
envsubst < $DIR/master-pitr-pv.json |  oc create -f -

# set up the claim for the backup archive 
envsubst <  $DIR/master-pitr-restore-pv.json  | oc create -f -

# set up the claim for the pgdata to live
envsubst <  $DIR/master-pitr-restore-pgdata-pv.json  | oc create -f -

# set up the claim for the WAL to recover with
envsubst <  $DIR/master-pitr-recover-pv.json  | oc create -f -

# set up the NFS claim to store the WAL into
oc create -f $DIR/master-pitr-wal-pvc.json

# set up the NFS claim to store the pgdata into
oc create -f $DIR/master-pitr-pvc.json

# start up the database container
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $DIR/master-pitr.json | oc create -f -
