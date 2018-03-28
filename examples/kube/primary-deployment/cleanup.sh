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

${CCP_CLI?} delete deploy primary-deployment replica-deployment replica2-deployment
${CCP_CLI?} delete configmap primary-deployment-pgconf
${CCP_CLI?} delete secret pguser-secret pgprimary-secret pgroot-secret
sleep 10
${CCP_CLI?} delete service primary-deployment
${CCP_CLI?} delete service replica-deployment
${CCP_CLI?} delete pvc primary-deployment-pgwal primary-deployment-pgbackrest primary-deployment-pgdata
${CCP_CLI?} delete pvc replica-deployment-pgwal replica-deployment-pgbackrest replica-deployment-pgdata
${CCP_CLI?} delete pvc replica2-deployment-pgwal replica2-deployment-pgbackrest replica2-deployment-pgdata
