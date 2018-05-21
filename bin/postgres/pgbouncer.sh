#!/bin/bash

source /opt/cpm/bin/common_lib.sh
export PGHOST="${PGHOST:-/tmp}"
enable_debugging
ose_hack

pgisready 'postgres' ${PGHOST?} 5432 'postgres'

echo_info "pgBouncer enabled.  Running setup SQL.."
cp /opt/cpm/bin/pgbouncer.sql /tmp
sed -i "s/PGBOUNCER_PASSWORD/${PGBOUNCER_PASSWORD?}/g" /tmp/pgbouncer.sql

for DB in $(psql -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1')")
do
    psql -U postgres -d ${DB?} < /tmp/pgbouncer.sql > /dev/null 2>&1
done

rm -f /tmp/pgbouncer.sql
