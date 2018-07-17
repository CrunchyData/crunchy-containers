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

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} deployment primary-deployment
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} statefulsets replica-deployment
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} configmap primary-deployment-pgconf
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} secret pgprimary-secret
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} service primary-deployment replica-deployment
${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pvc primary-deployment-pgdata replica-deployment-pgdata replica2-deployment-pgdata

if [ -z "$CCP_STORAGE_CLASS" ]
then
  ${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} pv primary-deployment-pgdata replica-deployment-pgdata
fi

dir_check_rm "primary-deployment"
dir_check_rm "replica-deployment"
