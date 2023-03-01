#!/bin/bash

# Copyright 2019 - 2023 Crunchy Data Solutions, Inc.
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

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"
enable_debugging

source "${CRUNCHY_DIR}/bin/postgres-ha/common/pgha-common.sh"

# set the Patroni port
export $(get_patroni_port)

# set PGHA_REPLICA_REINIT_ON_START_FAIL, which determines if replica should be reinitialized
# if a start failure is detected
export $(get_replica_reinit_start_fail)

# set the name of this Patroni node, i.e. env var PATRONI_NAME
export $(get_patroni_name)

# get the role and state of the local Patroni node by calling the "patroni" endpoint
local_node_json=$(curl --silent "127.0.0.1:${PGHA_PATRONI_PORT}/patroni" --stderr - )
role=$(echo "${local_node_json}" | "${CRUNCHY_DIR}/bin/yq" r - role)
state=$(echo "${local_node_json}" | "${CRUNCHY_DIR}/bin/yq" r - state)

# determine if a backup is in progress following a failover (i.e. the promotion of a replica)
# by looking for the "failover_backup_status" tag in the DCS
primary_on_role_change=$(curl --silent "127.0.0.1:${PGHA_PATRONI_PORT}/config" \
    | "${CRUNCHY_DIR}/bin/yq" r - tags.primary_on_role_change)

# if configured to reinit a replica when a "start failed" state is detected, and if a backup
# is not current in progress following a failover, then reinitialize the replica by calling
# the "reinitialize" endpoint on the local Patroni node
if [[ "${PGHA_REPLICA_REINIT_ON_START_FAIL}" == "true" && "${role}" == "replica" \
    && "${state}" == "start failed" && "${primary_on_role_change}" != "true" ]]
then
    # reinitialize the local Patroni node
    curl --silent -XPOST -d '{"force":true}' "127.0.0.1:${PGHA_PATRONI_PORT}/reinitialize"
fi


# always exit with exit code 0 to prevent restarts
exit 0
