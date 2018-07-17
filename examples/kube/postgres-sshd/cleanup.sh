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
echo_info "Cleaning up.."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} service postgres-sshd
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pod postgres-sshd
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} configmap postgres-sshd-pgconf
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} secret postgres-sshd-secrets

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pvc postgres-sshd-backrestrepo postgres-sshd-pgdata

if [ -z "$CCP_STORAGE_CLASS" ]; then
  ${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pv postgres-sshd-backrestrepo postgres-sshd-pgdata
fi

$CCPROOT/examples/waitforterm.sh postgres-sshd ${CCP_CLI?}
rm -rf ${DIR?}/keys

dir_check_rm "archive"
dir_check_rm "backup"
dir_check_rm "postgres-sshd"
file_check_rm "db-stanza-create.log"
