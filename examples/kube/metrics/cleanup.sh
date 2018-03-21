#!/bin/bash

# Copyright 2018 Crunchy Data Solutions, Inc.
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

kubectl delete clusterrolebinding prometheus
kubectl delete clusterrole prometheus
kubectl delete sa prometheus
kubectl delete pod crunchy-metrics
kubectl delete pod crunchy-pgsql
kubectl delete service crunchy-metrics
kubectl delete service crunchy-pgsql

kubectl delete pvc metrics-prometheus-pvc
kubectl delete pvc metrics-grafana-pvc

$CCPROOT/examples/waitforterm.sh crunchy-metrics kubectl
$CCPROOT/examples/waitforterm.sh crunchy-pgsql kubectl
