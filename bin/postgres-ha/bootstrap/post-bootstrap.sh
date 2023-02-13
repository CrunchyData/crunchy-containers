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

export PGHOST="/tmp"

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"
enable_debugging

echo_info "postgres-ha post-bootstrap starting"

if [[ "${PGHA_BOOTSTRAP_METHOD}" == "initdb" ]]
then
    # Run either a custom or the defaul setup.sql file
    if [[ -f "/pgconf/setup.sql" ]]
    then
        echo_info "Using custom setup.sql"
        setup_file="/pgconf/setup.sql"
    else
        echo_info "Using default setup.sql"
        setup_file="${CRUNCHY_DIR}/bin/postgres-ha/sql/setup.sql"
    fi
else
    if [[ -f "/pgconf/post-existing-init.sql" ]]
    then
        echo_info "Using custom post-existing-init.sql"
        setup_file="/pgconf/post-existing-init.sql"
    else
        echo_info "Using default post-existing-init.sql"
        setup_file="${CRUNCHY_DIR}/bin/postgres-ha/sql/post-existing-init.sql"
    fi
fi

echo_info "Running ${setup_file} file"
envsubst < "${setup_file}" | psql -f -

echo_info "postgres-ha post-bootstrap complete"
