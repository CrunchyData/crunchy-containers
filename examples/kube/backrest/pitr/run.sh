#!/bin/bash
# Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
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
${CCP_CLI?} exec --namespace=${CCP_NAMESPACE?} -ti backrest date >/dev/null
if [[ $? -ne 0 ]]
then
    echo_err "The backup example must be running prior to using this example."
    exit 1
fi

export PITR_TARGET="$(${CCP_CLI?} exec --namespace=${CCP_NAMESPACE?} -ti backrest -- psql -U postgres -Atc 'select current_timestamp' | tr -d '\r')"
if [[ -z ${PITR_TARGET} ]]
then
    echo_err "PITR_TARGET env is empty, it shouldn't be."
    exit 1
fi

${DIR}/cleanup.sh

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} \
    configmap br-pitr-restore-pgconf \
    --from-file ${DIR?}/configs/pgbackrest.conf

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap \
    br-pitr-restore-pgconf cleanup=${CCP_NAMESPACE?}-backrest-pitr-restore

expenv -f $DIR/pitr-restore.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
