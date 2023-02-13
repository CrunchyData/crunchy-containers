#!/bin/bash

# Copyright 2020 - 2023 Crunchy Data Solutions, Inc.
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
export $(get_patroni_pgdata_dir)

echo_info "Bootstrapping a new PostgreSQL cluster using an existing PGDATA directory"

mv "${PATRONI_POSTGRESQL_DATA_DIR}_tmp" "${PATRONI_POSTGRESQL_DATA_DIR}"
err_check "$?" "Initialize Existing PGDATA" "Could not initialize cluster using existing PGDATA directory"

# ensure the PGDATA directory has the proper permissions
chmod u+rwx,go-rwx "${PATRONI_POSTGRESQL_DATA_DIR}"

echo_info "Finished bootstrapping a new PostgreSQL cluster using an existing PGDATA directory"
