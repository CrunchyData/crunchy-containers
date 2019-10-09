#!/bin/bash

# Copyright 2016 - 2019 Crunchy Data Solutions, Inc.
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
    if [[ ${PG_MODE?} == "primary" ]] || [[ ${PG_MODE?} == "master" ]]
    then

        echo_info "PGMONITOR_PASSWORD detected.  Enabling pgMonitor support."

        source /opt/cpm/bin/common_lib.sh
        export PGHOST="${PGHOST:-/tmp}"

        pgisready 'postgres' ${PGHOST?} "${PG_PRIMARY_PORT}" 'postgres'
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
        elif (( ${VERSION?} >= 110000 ))
        then
            function_file='/opt/cpm/bin/modules/pgexporter/setup_pg11.sql'
        else
            echo_err "Unknown or unsupported version of PostgreSQL.  Exiting.."
            exit 1
        fi

        echo_info "Using setup file '${function_file}' for pgMonitor"
        cp "${function_file}" "/tmp/setup_pg.sql"
        sed -i "s/\/usr\/bin\/pgbackrest-info.sh/\/opt\/cpm\/bin\/pgbackrest_info.sh/g" "/tmp/setup_pg.sql"

        # TODO Add ON_ERROR_STOP and single transaction when
        # upstream pgmonitor changes setup SQL to check if the
        # role exists prior to creating it.
        psql -U postgres --port="${PG_PRIMARY_PORT}" -d postgres \
            < "/tmp/setup_pg.sql" > /tmp/pgmonitor-setup.stdout 2> /tmp/pgmonitor-setup.stderr

        #err_check "$?" "pgMonitor Setup" "Could not load pgMonitor functions: \n$(cat /tmp/pgmonitor.stderr)"

        psql -U postgres --port="${PG_PRIMARY_PORT}" -d postgres \
            -c "ALTER ROLE ccp_monitoring PASSWORD '${PGMONITOR_PASSWORD?}'" \
            > /tmp/pgmonitor-alter-role.stdout 2> /tmp/pgmonitor-alter-role.stderr

        #err_check "$?" "pgMonitor User Setup" "Could not alter ccp_monitor user's password: \n$(cat /tmp/pgmonitor.stderr)"
    fi
fi
