#!/bin/bash

 # Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
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

echo_info "Executing post-start-hook..." # add below this line

if [[ ${PG_MODE?} == "primary" ]]
then
    echo_info "Setting up pgBouncer authorizations..."
    source /opt/cpm/bin/common_lib.sh
    export PGHOST="${PGHOST:-/tmp}"
    enable_debugging

    pgisready 'postgres' ${PGHOST?} "${PG_PRIMARY_PORT}" 'postgres'

    cp /pgconf/pgbouncer-auth.sql /tmp
    sed -i "s/PGBOUNCER_PASSWORD/${PGBOUNCER_PASSWORD?}/g" /tmp/pgbouncer-auth.sql

    for DB in $(psql --port="${PG_PRIMARY_PORT}" -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1')")
    do
	psql -U postgres -d ${DB?} --port="${PG_PRIMARY_PORT}" \
	     --single-transaction \
	     -v ON_ERROR_STOP=1 < /tmp/pgbouncer-auth.sql > /tmp/pgbouncer-auth.stdout 2> /tmp/pgbouncer-auth.stderr
	err_check "$?" "pgBouncer User Setup" "Could not create pgBouncer user: \n$(cat /tmp/pgbouncer-auth.stderr)"
    done
    rm -f /tmp/pgbouncer.sql
fi
