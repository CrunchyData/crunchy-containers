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

sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/primary-dc

oc delete service primary-dc replica-dc
oc delete deployments primary-dc replica-dc replica2-dc

oc delete configmap postgresql-conf
oc delete secret pguser-secret pgprimary-secret pgroot-secret\
	
oc delete pvc primary-dc-pvc primary-dc-pgbackrest-pvc primary-dc-pgwal-pvc
oc delete pvc replica-dc-pvc replica-dc-pgbackrest-pvc replica-dc-pgwal-pvc
oc delete pvc replica2-dc-pvc replica2-dc-pgbackrest-pvc replica2-dc-pgwal-pvc
