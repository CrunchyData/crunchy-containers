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

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

TEMP_FILE=${1?}
JOB_HOST=${2?}
CMD=${3?}

echo_info "Deleting vacuum job ${JOB_HOST?}.."
/opt/cpm/bin/${CMD?} delete job ${JOB_HOST?}-vac
sleep 15

echo_info "Creating vacuum job.."
/opt/cpm/bin/${CMD?} create -f ${TEMP_FILE?}

exit 0
