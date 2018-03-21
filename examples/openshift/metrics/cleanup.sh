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

oc delete clusterrolebinding prometheus
oc delete clusterrole prometheus
oc delete sa prometheus
oc delete pod crunchy-metrics
oc delete pod crunchy-pgsql
oc delete service crunchy-metrics
oc delete service crunchy-pgsql

oc delete pvc metrics-prometheus-pvc
oc delete pvc metrics-grafana-pvc

$CCPROOT/examples/waitforterm.sh crunchy-metrics oc
$CCPROOT/examples/waitforterm.sh crunchy-pgsql oc
