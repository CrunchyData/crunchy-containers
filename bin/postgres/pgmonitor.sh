#!/bin/bash

source /opt/cpm/bin/common_lib.sh
export PGHOST="${PGHOST:-/tmp}"

pgisready 'postgres' ${PGHOST?} "${PG_PRIMARY_PORT}" 'postgres'
VERSION=$(psql -d postgres -qtAX -c "SELECT current_setting('server_version_num')")

if (( ${VERSION?} > 90500 )) && (( ${VERSION?} < 100000 ))
then
    function_file='/opt/cpm/bin/pgmonitor/functions_pg92-96.sql'
elif (( ${VERSION?} >= 100000 )) && (( ${VERSION?} < 120000 ))
then
    function_file='/opt/cpm/bin/pgmonitor/functions_pg10.sql'
else
    echo_err "Unknown or unsupported version of PostgreSQL.  Exiting.."
    exit 1
fi

# TODO Add ON_ERROR_STOP and single transaction when
# upstream pgmonitor changes setup SQL to check if the
# role exists prior to creating it.
psql -U postgres -d postgres \
    < ${function_file?} > /tmp/pgmonitor.stdout 2> /tmp/pgmonitor.stderr

err_check "$?" "pgMonitor Setup" "Could not load pgMonitor functions: \n$(cat /tmp/pgmonitor.stderr)"

psql -U postgres -d postgres \
    -c "ALTER ROLE ccp_monitoring PASSWORD '${PGMONITOR_PASSWORD?}'" \
    > /tmp/pgmonitor.stdout 2> /tmp/pgmonitor.stderr

err_check "$?" "pgMonitor User Setup" "Could not alter ccp_monitor user's password: \n$(cat /tmp/pgmonitor.stderr)"
