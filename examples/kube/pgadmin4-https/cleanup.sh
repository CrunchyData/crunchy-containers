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
echo_info "Cleaning up.."

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} service pgadmin4-https
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pod pgadmin4-https
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} secret pgadmin4-https-secrets
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} secret pgadmin4-https-tls

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pvc pgadmin4-https-data

if [ -z "$CCP_STORAGE_CLASS" ]; then
  ${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pv pgadmin4-https-data
fi

rm -f ${DIR?}/server.crt ${DIR?}/server.key ${DIR?}/privkey.pem

$CCPROOT/examples/waitforterm.sh pgadmin4-https ${CCP_CLI?}

file_check_rm "access_log"
file_check_rm "config_local.py"
file_check_rm "error_log"
file_check_rm "pgadmin4.db"
file_check_rm "pgadmin4.conf"
file_check_rm "pgadmin.log"
file_check_rm "sessions"
file_check_rm "storage"
