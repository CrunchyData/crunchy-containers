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

source ${CCPROOT}/examples/common.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${DIR}/cleanup.sh

${CCP_CLI?} create -f ${DIR?}/elasticsearch-statefulset.yaml
${CCP_CLI?} create -f ${DIR?}/fluentd-configmap.yaml
${CCP_CLI?} create -f ${DIR?}/fluentd-daemonset.yaml
${CCP_CLI?} create -f ${DIR?}/kibana-deployment.yaml

echo_info "Sleeping until EFK stack is ready.."
sleep 45

# Replicate shards to all hosts
URL='http://localhost:9200'
${CCP_CLI?} exec -ti elasticsearch-logging-0 -n kube-system \
  -- curl -XPUT "${URL?}/_cluster/settings" -H 'Content-Type: application/json' -d'
{
    "transient": {
        "cluster.routing.allocation.enable": "all"
    }
}'
