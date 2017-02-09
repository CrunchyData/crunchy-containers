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
kubectl create -f $DIR/ks-master-service.json
kubectl create -f $DIR/ks-replica-service.json
kubectl create -f $DIR/ks-pgpool-service.json

echo "create master pod.."
envsubst < $DIR/ks-master-pod.json | kubectl create -f -
echo "create replica pod.."
envsubst < $DIR/ks-replica-dc.json | kubectl create -f -
echo "create sync replica pod.."
envsubst < $DIR/ks-sync-replica-pod.json | kubectl create -f -
sleep 20
echo "create pgpool rc..."
envsubst < $DIR/ks-pgpool-rc.json | kubectl create -f -
echo "create watch service account and pod"
kubectl create -f $DIR/ks-watch-sa.json
envsubst <  $DIR/ks-watch-pod.json | kubectl create -f -
