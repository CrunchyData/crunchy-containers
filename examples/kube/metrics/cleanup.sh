#!/bin/bash

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
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

${CCP_CLI?} delete clusterrolebinding prometheus
${CCP_CLI?} delete clusterrole prometheus
${CCP_CLI?} delete sa prometheus
${CCP_CLI?} delete pod crunchy-metrics
${CCP_CLI?} delete pod crunchy-pgsql
${CCP_CLI?} delete service crunchy-metrics
${CCP_CLI?} delete service crunchy-pgsql

${CCP_CLI?} delete pvc metrics-prometheus-pvc
${CCP_CLI?} delete pvc metrics-grafana-pvc

$CCPROOT/examples/waitforterm.sh crunchy-metrics ${CCP_CLI?}
$CCPROOT/examples/waitforterm.sh crunchy-pgsql ${CCP_CLI?}
