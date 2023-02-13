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
CONTAINER_NAME="postgres-gis-ha"

${DIR}/cleanup.sh

create_storage "${CONTAINER_NAME}" "${CCP_NAMESPACE?}"
if [[ $? -ne 0 ]]
then
    echo_err "Failed to create storage, exiting.."
    exit 1
fi

cat $DIR/postgres-gis-ha-rbac.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic ${CONTAINER_NAME?}-pguser \
    --from-file=username=${DIR?}/credentials/pguser/username \
    --from-file=password=${DIR?}/credentials/pguser/password

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} secret \
    ${CONTAINER_NAME?}-pguser cleanup=${CCP_NAMESPACE?}-${CONTAINER_NAME?}

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic ${CONTAINER_NAME?}-pgsuper \
    --from-file=username=${DIR?}/credentials/pgsuper/username \
    --from-file=password=${DIR?}/credentials/pgsuper/password

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} secret \
    ${CONTAINER_NAME?}-pgsuper cleanup=${CCP_NAMESPACE?}-${CONTAINER_NAME?}

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic ${CONTAINER_NAME?}-pgreplicator \
    --from-file=username=${DIR?}/credentials/pgreplicator/username \
    --from-file=password=${DIR?}/credentials/pgreplicator/password

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} secret \
    ${CONTAINER_NAME?}-pgreplicator cleanup=${CCP_NAMESPACE?}-${CONTAINER_NAME?}

cat $DIR/postgres-gis-ha.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
