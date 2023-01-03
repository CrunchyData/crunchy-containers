#!/bin/bash
# Copyright 2018 - 2023 Crunchy Data Solutions, Inc.
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

set -e

source ${CCPROOT}/examples/common.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo_info "Executing SQL in pgaudit pod.."
${CCP_CLI?} exec --namespace=${CCP_NAMESPACE?} -ti pgaudit -- psql -d userdb -f /pgconf/pgaudit-test.sql

echo_info "Checking logs for audit entries.."
logs=$(${CCP_CLI?} --namespace=${CCP_NAMESPACE?} logs pgaudit | grep AUDIT)
log_count=$(echo "$logs" | wc -l | xargs)

if [[ ${log_count:-0} < 1 ]]
then
    echo "No audit logs found. Exiting.."
    exit 1
else
    echo "Audit logs found!"
    echo "$logs"
fi

exit 0
