#!/bin/bash
# Copyright 2017 - 2019 Crunchy Data Solutions, Inc.
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

# Cleanup backrest pods if they're running from backup examples
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pod,service backrest

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} \
    configmap br-delta-restore-pgconf \
    --from-file ${DIR?}/configs/pgbackrest.conf

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap \
    br-delta-restore-pgconf cleanup=${CCP_NAMESPACE?}-backrest-delta-restore

expenv -f $DIR/delta-restore.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
