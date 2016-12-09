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

echo "create services for master and replicas..."
kubectl create -f $DIR/kitchensink-master-service.json
kubectl create -f $DIR/kitchensink-replica-service.json
kubectl create -f $DIR/kitchensink-pgpool-service.json

echo "create PVs for master and sync replica..."
envsubst < $LOC/kitchensink-sync-replica-pv.json | kubectl create -f -
envsubst < $LOC/kitchensink-master-pv.json | kubectl create -f -

echo "create PVCs for master and sync replica..."
kubectl create -f $LOC/kitchensink-sync-replica-pvc.json
kubectl create -f $LOC/kitchensink-master-pvc.json

echo "create master pod.."
envsubst < $LOC/kitchensink-master-pod.json | kubectl create -f -
echo "sleeping 20 secs before creating replicas..."
sleep 20
echo "create replica pod.."
envsubst < $LOC/kitchensink-replica-dc.json | kubectl create -f -
echo "create sync replica pod.."
envsubst < $LOC/kitchensink-sync-replica-pod.json | kubectl create -f -
echo "create pgpool rc..."
envsubst < $LOC/kitchensink-pgpool-rc.json | kubectl create -f -

echo "create watch service account and pod"
kubectl create -f $LOC/kitchensink-watch-sa.json
envsubst <  $LOC/kitchensink-watch-pod.json | kubectl create -f -
