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

create_storage "custom-config"
if [[ $? -ne 0 ]]
then
    echo_err "Failed to create storage, exiting.."
    exit 1
fi

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap custom-config-pgconf \
    --from-file ${DIR?}/configs/pg_hba.conf \
    --from-file ${DIR?}/configs/postgresql.conf \
    --from-file ${DIR?}/configs/setup.sql \
    --from-file ${DIR?}/configs/pre-start-hook.sh \
    --from-file ${DIR?}/configs/post-start-hook.sh

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap \
    custom-config-pgconf cleanup=${CCP_NAMESPACE?}-custom-config

cat $DIR/custom-config.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
