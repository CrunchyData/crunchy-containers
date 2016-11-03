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

LOC=$BUILDBASE/examples/openshift/kitchensink

echo "create services for master and slaves..."
oc create -f $LOC/kitchensink-master-service.json
oc create -f $LOC/kitchensink-slave-service.json

echo "create PVCs for master and sync slave..."
oc create -f $LOC/kitchensink-sync-slave-pvc.json
oc create -f $LOC/kitchensink-master-pvc.json

echo "create master pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/kitchensink-master-pod.json | oc create -f -
echo "sleeping 20 secs before creating slaves..."
sleep 20
echo "create slave pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/kitchensink-slave-dc.json | oc create -f -
echo "create sync slave pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/kitchensink-sync-slave-pod.json | oc create -f -
echo "create pgpool rc..."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/kitchensink-pgpool-rc.json | oc create -f -
echo "create watch service account and pod"
oc create -f $LOC/kitchensink-watch-sa.json
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/kitchensink-watch-pod.json | oc create -f -
