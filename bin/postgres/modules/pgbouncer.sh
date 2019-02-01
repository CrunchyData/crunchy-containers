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

if [[ -v PGBOUNCER_PASSWORD ]]
then
    if [[ ${PG_MODE?} == "primary" ]] || [[ ${PG_MODE?} == "master" ]]
    then
        echo_info "pgBouncer Password detected.  Setting up pgBouncer.."

        source /opt/cpm/bin/common_lib.sh
        export PGHOST="${PGHOST:-/tmp}"
        enable_debugging

        pgisready 'postgres' ${PGHOST?} "${PG_PRIMARY_PORT}" 'postgres'

        echo_info "pgBouncer enabled.  Running setup SQL.."
        cp /opt/cpm/bin/modules/pgbouncer.sql /tmp
        sed -i "s/PGBOUNCER_PASSWORD/${PGBOUNCER_PASSWORD?}/g" /tmp/pgbouncer.sql

        for DB in $(psql --port="${PG_PRIMARY_PORT}" -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1')")
        do
            psql -U postgres -d ${DB?} --port="${PG_PRIMARY_PORT}" \
                --single-transaction \
                -v ON_ERROR_STOP=1 < /tmp/pgbouncer.sql > /tmp/pgbouncer.stdout 2> /tmp/pgbouncer.stderr
            err_check "$?" "pgBouncer User Setup" "Could not create pgBouncer user: \n$(cat /tmp/pgbouncer.stderr)"
        done

        rm -f /tmp/pgbouncer.sql
    fi
fi
