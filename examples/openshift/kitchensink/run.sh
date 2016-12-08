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

echo "create PVs for master and sync replica..."
envsubst < $DIR/kitchensink-sync-replica-pv.json | oc create -f -
envsubst < $DIR/kitchensink-master-pv.json | oc create -f -

echo "create services for master and replicas..."
oc create -f $DIR/kitchensink-master-service.json
oc create -f $DIR/kitchensink-replica-service.json

echo "create PVCs for master and sync replica..."
oc create -f $DIR/kitchensink-sync-replica-pvc.json
oc create -f $DIR/kitchensink-master-pvc.json

echo "create master pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $DIR/kitchensink-master-pod.json | oc create -f -
echo "sleeping 20 secs before creating replicas..."
sleep 20
echo "create replica pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $DIR/kitchensink-replica-dc.json | oc create -f -
echo "create sync replica pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $DIR/kitchensink-sync-replica-pod.json | oc create -f -
echo "create pgpool rc..."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $DIR/kitchensink-pgpool-rc.json | oc create -f -
echo "create watch service account and pod"
oc create -f $DIR/kitchensink-watch-sa.json
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $DIR/kitchensink-watch-pod.json | oc create -f -
