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

# 
# this example creates the metrics backends with NFS volumes
# for storing their data
#
source $BUILDBASE/examples/envvars.sh
LOC=$BUILDBASE/examples/kube/metrics

envsubst <  $LOC/grafana-pv.json |  kubectl create -f -
envsubst <  $LOC/prometheus-pv.json | kubectl create -f -

kubectl create -f $LOC/grafana-pvc.json
kubectl create -f $LOC/prometheus-pvc.json

kubectl create -f $LOC/prometheus-service.json
kubectl create -f $LOC/promgateway-service.json
kubectl create -f $LOC/grafana-service.json

envsubst < $LOC/prometheus-nfs.json | kubectl create -f -
envsubst < $LOC/promgateway.json | kubectl create -f -
envsubst < $LOC/grafana-nfs.json | kubectl create -f -
