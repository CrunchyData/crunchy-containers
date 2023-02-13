#!/bin/bash
# Copyright 2017 - 2023 Crunchy Data Solutions, Inc.
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

if [[ -z ${CCP_BACKREST_TIMESTAMP} ]]
then
    echo_err "Please provide a valid timestamp for the delta PITR using varibale CCP_BACKREST_TIMESTAMP."
    exit 1
fi

pod=$(${CCP_CLI?} get pods --namespace=${CCP_NAMESPACE?} --no-headers -l name=backrest | awk '{print $1}')

${CCP_CLI?} exec --namespace=${CCP_NAMESPACE?} -ti ${pod?} date >/dev/null
if [[ $? -ne 0 ]]
then
    echo_err "The backup example must be running prior to using this example."
    exit 1
fi

${DIR}/cleanup.sh

# Cleanup backrest pods if they're running from backup examples
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} deployment,service backrest

cat $DIR/delta-restore.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
