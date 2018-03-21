#!/bin/bash

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
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

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

BACKUP_TEMPLATE=${1?}
BACKUP_PVC_TEMPLATE=${2?}
JOB_HOST=${3?}
CMD=${4?}

echo_info "Deleting backup job ${JOB_HOST?}.."
/opt/cpm/bin/${CMD?} delete job ${JOB_HOST?}-backup
sleep 15

echo_info "Creating Backup PVC ${BACKUP_PVC_TEMPLATE?}.."
/opt/cpm/bin/${CMD?} create -f ${BACKUP_PVC_TEMPLATE?}
sleep 4

echo_info "Creating backup job ${BACKUP_TEMPLATE?}.."
/opt/cpm/bin/$4 create -f $1

exit 0
