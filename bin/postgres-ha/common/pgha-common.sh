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

PATRONI_PID=$(pgrep -f "patroni" | head -1)

# Get the Patroni port from the running Patroni process
get_patroni_port() {
    pgha_patroni_port=$( tr '\0' '\n' < /proc/"${PATRONI_PID}"/environ  | grep ^PGHA_PATRONI_PORT= )
    echo "${pgha_patroni_port}"
}

# Get the PGHA_PGBACKREST env var, which determines if pgBackRest is enabled
get_pgbackrest_enabled() {
    pgha_pgbackrest=$( tr '\0' '\n' < /proc/"${PATRONI_PID}"/environ  | \
        grep ^PGHA_PGBACKREST= )
    echo "${pgha_pgbackrest}"
}

# Get the PGHA_PGBACKREST env var to determine if replicas should reinit on a start failure
get_replica_reinit_start_fail() {
    pgha_replica_reinit_on_start_fail=$( tr '\0' '\n' < /proc/"${PATRONI_PID}"/environ | \
        grep ^PGHA_REPLICA_REINIT_ON_START_FAIL= )
    echo  "${pgha_replica_reinit_on_start_fail}"
}

# Get the PGHA_PGBACKREST env var to determine if replicas should reinit on a start failure
get_patroni_name() {
    patroni_name=$( tr '\0' '\n' < /proc/"${PATRONI_PID}"/environ | \
        grep ^PATRONI_NAME= )
    echo  "${patroni_name}"
}

# Get the PATRONI_POSTGRESQL_DATA_DIR env var to determine the PGDATA directory
get_patroni_pgdata_dir() {
    patroni_pgdata_dir=$( tr '\0' '\n' < /proc/"${PATRONI_PID}"/environ | \
        grep ^PATRONI_POSTGRESQL_DATA_DIR= )
    echo  "${patroni_pgdata_dir}"
}
