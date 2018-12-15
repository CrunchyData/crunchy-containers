#!/bin/bash
# Copyright 2016 - 2019 Crunchy Data Solutions, Inc.
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

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} svc restore-pitr
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pod restore-pitr pitr

$CCPROOT/examples/waitforterm.sh pitr ${CCP_CLI?}
$CCPROOT/examples/waitforterm.sh restore-pitr ${CCP_CLI?}

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pvc recover-pvc restore-pitr-pgdata
if [[ -z "$CCP_STORAGE_CLASS" ]]
then
    ${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pv ${CCP_NAMESPACE?}-recover-pv ${CCP_NAMESPACE?}-restore-pitr-pgdata
fi

dir_check_rm "restore-pitr"
create_storage "restore-pitr"
if [[ $? -ne 0 ]]
then
    echo_err "Failed to create storage, exiting.."
    exit 1
fi

expenv -f $DIR/restore-pitr.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
