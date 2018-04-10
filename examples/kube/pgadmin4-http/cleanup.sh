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

${CCP_CLI?} delete service pgadmin4-http
${CCP_CLI?} delete pod pgadmin4-http
${CCP_CLI?} delete secret pgadmin4-http-secrets
${CCP_CLI?} delete pvc pgadmin4-http-data
if [ -z "$CCP_STORAGE_CLASS" ]; then
  ${CCP_CLI?} delete pv pgadmin4-http-data
fi

$CCPROOT/examples/waitforterm.sh pgadmin4-http ${CCP_CLI?}
