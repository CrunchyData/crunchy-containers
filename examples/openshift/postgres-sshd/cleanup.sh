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

oc delete service postgres-sshd
oc delete pod postgres-sshd
oc delete configmap pgconf
oc delete secret sshd-secrets

oc delete pvc postgres-sshd-pvc postgres-sshd-backrest-pvc

$CCPROOT/examples/waitforterm.sh postgres-sshd oc
rm -rf ${DIR?}/keys
 
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/postgres-sshd $CCP_STORAGE_PATH/db-stanza-create.log
