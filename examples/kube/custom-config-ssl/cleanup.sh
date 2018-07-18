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
echo_info "Cleaning up.."

CONFDIR=$CCP_STORAGE_PATH/custom-config-ssl-pgconf
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} service custom-config-ssl
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pod custom-config-ssl
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} secret custom-config-ssl-secrets
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pvc custom-config-ssl-pgdata custom-config-ssl-backrestrepo

if [[ -z "$CCP_STORAGE_CLASS" ]]
then
    ${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pv custom-config-ssl-pgdata custom-config-pgwal custom-config-ssl-backrestrepo
fi

$CCPROOT/examples/waitforterm.sh custom-config-ssl ${CCP_CLI?}

dir_check_rm "archive"
dir_check_rm "backup"
dir_check_rm "custom-config-ssl"
file_check_rm "db-stanza-create.log"

rm -rf ${DIR?}/certs
rm -rf ${DIR?}/out
rm -f ${DIR?}/configs/ca.* ${DIR?}/configs/server.*
