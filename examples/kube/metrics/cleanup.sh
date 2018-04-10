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

${CCP_CLI?} delete clusterrolebinding prometheus-sa
${CCP_CLI?} delete clusterrole prometheus-sa
${CCP_CLI?} delete sa prometheus-sa
${CCP_CLI?} delete pod metrics
${CCP_CLI?} delete pod pgsql
${CCP_CLI?} delete service metrics
${CCP_CLI?} delete service pgsql

${CCP_CLI?} delete pvc metrics-prometheusdata
${CCP_CLI?} delete pvc metrics-grafanadata
if [ -z "$CCP_STORAGE_CLASS" ]; then
  ${CCP_CLI?} delete pv metrics-prometheusdata metrics-grafanadata
fi

$CCPROOT/examples/waitforterm.sh metrics ${CCP_CLI?}
$CCPROOT/examples/waitforterm.sh pgsql ${CCP_CLI?}
