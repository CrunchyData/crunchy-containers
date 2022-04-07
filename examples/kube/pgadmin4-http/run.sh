#!/bin/bash
# Copyright 2018 - 2022 Crunchy Data Solutions, Inc.
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

create_storage "pgadmin4-http"
if [[ $? -ne 0 ]]
then
    echo_err "Failed to create storage, exiting.."
    exit 1
fi

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic pgadmin4-http-secrets \
    --from-literal=pgadmin-email='admin@admin.com' \
    --from-literal=pgadmin-password='password'

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} secret \
    pgadmin4-http-secrets cleanup=${CCP_NAMESPACE?}-pgadmin4-http

cat $DIR/pgadmin4-http.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
