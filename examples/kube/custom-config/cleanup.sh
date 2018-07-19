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

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} service custom-config
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pod custom-config
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pvc custom-config-pgdata custom-config-pgwal custom-config-br
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} configmap custom-config-pgconf

if [[ -z "$CCP_STORAGE_CLASS" ]]
then
    ${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pv custom-config-pgdata custom-config-pgwal custom-config-br
fi

$CCPROOT/examples/waitforterm.sh custom-config ${CCP_CLI?}

dir_check_rm "archive"
dir_check_rm "backup"
dir_check_rm "custom-config"
dir_check_rm "custom-config-wal"
file_check_rm "db-stanza-create.log"
