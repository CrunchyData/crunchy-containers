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

LOC=$BUILDBASE/examples/openshift/pitr

# set up the NFS claim to store the WAL into
envsubst < master-pitr-wal-pv.json |  oc create -f -
oc create -f master-pitr-wal-pvc.json

# set up the NFS claim to store the pgdata into
envsubst < master-pitr-pv.json |  oc create -f -
oc create -f master-pitr-pvc.json

# start up the database container
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/master-pitr.json | oc create -f -
