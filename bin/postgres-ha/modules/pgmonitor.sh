#!/bin/bash

# Copyright 2019 - 2020 Crunchy Data Solutions, Inc.
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

if [[ -v PGMONITOR_PASSWORD ]]
then
    echo_info "PGMONITOR_PASSWORD detected.  Enabling pgMonitor support."

    source /opt/cpm/bin/common/common_lib.sh
    export PGHOST="/tmp"

    test_server "postgres" "${PGHOST?}" "${PGHA_PG_PORT}" "postgres"
    VERSION=$(psql --port="${PG_PRIMARY_PORT}" -d postgres -qtAX -c "SELECT current_setting('server_version_num')")

    if (( ${VERSION?} >= 90500 )) && (( ${VERSION?} < 90600 ))
    then
        function_file='/opt/cpm/bin/modules/pgexporter/setup_pg95.sql'
    elif (( ${VERSION?} >= 90600 )) && (( ${VERSION?} < 100000 ))
    then
        function_file='/opt/cpm/bin/modules/pgexporter/setup_pg96.sql'
    elif (( ${VERSION?} >= 100000 )) && (( ${VERSION?} < 110000 ))
    then
        function_file='/opt/cpm/bin/modules/pgexporter/setup_pg10.sql'
    elif (( ${VERSION?} >= 110000 )) && (( ${VERSION?} < 120000 ))
    then
        function_file='/opt/cpm/bin/modules/pgexporter/setup_pg11.sql'
    elif (( ${VERSION?} >= 120000 )) && (( ${VERSION?} < 130000 ))
    then
        function_file='/opt/cpm/bin/modules/pgexporter/setup_pg12.sql'
    elif (( ${VERSION?} >= 130000 ))
    then
        function_file='/opt/cpm/bin/modules/pgexporter/setup_pg13.sql'
    else
        echo_err "Unknown or unsupported version of PostgreSQL.  Exiting.."
        exit 1
    fi

    echo_info "Using setup file '${function_file}' for pgMonitor"
    cp "${function_file}" "/tmp/setup_pg.sql"
    sed -i "s/\/usr\/bin\/pgbackrest-info.sh/\/opt\/cpm\/bin\/pgbackrest\/pgbackrest_info.sh/g" "/tmp/setup_pg.sql"

    psql -U postgres --port="${PG_PRIMARY_PORT}" -d postgres \
        < "/tmp/setup_pg.sql" > /tmp/pgmonitor-setup.stdout 2> /tmp/pgmonitor-setup.stderr

    psql -U postgres --port="${PG_PRIMARY_PORT}" -d postgres \
        -c "SET log_statement TO 'none'; ALTER ROLE ccp_monitoring PASSWORD '${PGMONITOR_PASSWORD?}'" \
        > /tmp/pgmonitor-alter-role.stdout 2> /tmp/pgmonitor-alter-role.stderr

    psql -U postgres --port="${PG_PRIMARY_PORT}" -d postgres \
        -c "CREATE EXTENSION IF NOT EXISTS pgnodemx WITH SCHEMA monitor;" > /tmp/pgmonitor-setup.stdout 2> /tmp/pgmonitor-setup.stderr
fi
