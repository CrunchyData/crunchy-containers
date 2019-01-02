#!/bin/bash

source /opt/cpm/bin/common_lib.sh
export PGHOST="${PGHOST:-/tmp}"
enable_debugging

pgisready 'postgres' ${PGHOST?} 5432 'postgres'

echo_info "pgBouncer enabled.  Running setup SQL.."
cp /opt/cpm/bin/pgbouncer.sql /tmp
sed -i "s/PGBOUNCER_PASSWORD/${PGBOUNCER_PASSWORD?}/g" /tmp/pgbouncer.sql

for DB in $(psql -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1')")
do
    psql -U postgres -d ${DB?} \
        --single-transaction \
        -v ON_ERROR_STOP=1 < /tmp/pgbouncer.sql > /tmp/pgbouncer.stdout 2> /tmp/pgbouncer.stderr
    err_check "$?" "pgBouncer User Setup" "Could not create pgBouncer user: \n$(cat /tmp/pgbouncer.stderr)"
done

rm -f /tmp/pgbouncer.sql
