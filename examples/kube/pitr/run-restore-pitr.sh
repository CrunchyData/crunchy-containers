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

LOC=$BUILDBASE/examples/kube/pitr

# remove any existing components of this example 

kubectl delete pod master-pitr-restore
kubectl delete service master-pitr-restore
sudo rm -rf /nfsfileshare/master-pitr-restore
kubectl delete pvc master-pitr-restore-pvc master-pitr-restore-pgdata-pvc master-pitr-recover-pvc
kubectl delete pv master-pitr-restore-pv master-pitr-restore-pgdata-pv master-pitr-recover-pv

# set up the claim for the backup archive 
envsubst <  $LOC/master-pitr-restore-pv.json  | kubectl create -f -
kubectl create -f $LOC/master-pitr-restore-pvc.json

# set up the claim for the pgdata to live
envsubst <  $LOC/master-pitr-restore-pgdata-pv.json  | kubectl create -f -
kubectl create -f $LOC/master-pitr-restore-pgdata-pvc.json

# set up the claim for the WAL to recover with
envsubst <  $LOC/master-pitr-recover-pv.json  | kubectl create -f -
kubectl create -f $LOC/master-pitr-recover-pvc.json

# start up the database container
echo "sleeping for a bit to let old container die..."
sleep 60
envsubst <  $LOC/master-pitr-restore-service.json  | kubectl create -f -
envsubst <  $LOC/master-pitr-restore-pod.json  | kubectl create -f -
