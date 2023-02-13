#!/bin/bash
# Copyright 2018 - 2023 Crunchy Data Solutions, Inc.
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

pod=$(${CCP_CLI?} get pods --namespace=${CCP_NAMESPACE?} --no-headers -l name=primary | awk '{print $1}')
${CCP_CLI?} exec --namespace=${CCP_NAMESPACE?} -ti ${pod?} date >/dev/null
if [[ $? -ne 0 ]]
then
    echo_err "The primary example must be running prior to using this example."
    exit 1
fi

cp ${DIR?}/configs/transactions.sql /tmp/transactions.sql
if [[ ${CCP_PGVERSION?} == "9.5" ]]
then
    cp ${DIR?}/configs/transactions95.sql /tmp/transactions.sql
fi

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap pgbench-custom-pgconf \
    --from-file /tmp/transactions.sql

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap \
    pgbench-custom-pgconf cleanup=${CCP_NAMESPACE?}-pgbench-custom

cat $DIR/pgbench.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
