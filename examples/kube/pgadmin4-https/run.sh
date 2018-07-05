#!/bin/bash
# Copyright 2018 Crunchy Data Solutions, Inc.
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

create_storage "pgadmin4-https"
if [[ $? -ne 0 ]]
then
    echo_err "Failed to create storage, exiting.."
    exit 1
fi

openssl req -x509 -newkey rsa:4096 -keyout ${DIR?}/server.key -out ${DIR?}/server.crt -days 5 -nodes -subj '/CN=localhost'

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic pgadmin4-https-secrets \
    --from-literal=pgadmin-email='admin@admin.com' \
    --from-literal=pgadmin-password='password'

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic pgadmin4-https-tls \
    --from-file=pgadmin-cert=${DIR?}/server.crt \
    --from-file=pgadmin-key=${DIR?}/server.key

expenv -f $DIR/pgadmin4-https.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
