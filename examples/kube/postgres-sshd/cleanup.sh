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



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${CCP_CLI?} delete service postgres-sshd
${CCP_CLI?} delete pod postgres-sshd
${CCP_CLI?} delete configmap postgres-sshd-pgconf
${CCP_CLI?} delete secret postgres-sshd-secrets

${CCP_CLI?} delete pvc postgres-sshd-backrestrepo postgres-sshd-pgdata

$CCPROOT/examples/waitforterm.sh postgres-sshd ${CCP_CLI?}
rm -rf ${DIR?}/keys

sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/archive $CCP_STORAGE_PATH/backup
