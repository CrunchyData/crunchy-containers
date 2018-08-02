#!/bin/bash

source /opt/cpm/bin/common_lib.sh
export PGHOST="${PGHOST:-/tmp}"

pgisready 'postgres' ${PGHOST?} 5432 'postgres'
VERSION=$(psql -d postgres -qtAX -c "SELECT current_setting('server_version_num')")

if (( ${VERSION?} > 90500 )) && (( ${VERSION?} < 100000 ))
then
    psql -U postgres -d postgres < /opt/cpm/bin/pgmonitor/functions_pg92-96.sql > /dev/null 2>&1
elif (( ${VERSION?} >= 100000 )) && (( ${VERSION?} < 110000 ))
then
    psql -U postgres -d postgres < /opt/cpm/bin/pgmonitor/functions_pg10.sql > /dev/null 2>&1
else
    echo_err "Unknown or unsupported version of PostgreSQL.  Exiting.."
    exit 1
fi

psql -U postgres -d postgres -c "ALTER ROLE ccp_monitoring PASSWORD '${PGMONITOR_PASSWORD?}'"
