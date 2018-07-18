#!/bin/bash

set -e

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

export PGROOT=$(find /usr/ -type d -name 'pgsql-*')
export PGDUMP_PORT=${PGDUMP_PORT:-5432}
export PGDUMP_FILENAME=${PGDUMP_FILENAME:-dump}
export PGPASSFILE=/tmp/pgpass
export PGDUMP_CUSTOM_OPTS=${PGDUMP_CUSTOM_OPTS:-}

env_check_err "PGDUMP_DB"
env_check_err "PGDUMP_HOST"
env_check_err "PGDUMP_PASS"
env_check_err "PGDUMP_USER"

# Todo: Add SSL support
conn_opts="-h ${PGDUMP_HOST?} -p ${PGDUMP_PORT?} -U ${PGDUMP_USER?}"

cat >> "${PGPASSFILE?}" <<-EOF
*:*:*:${PGDUMP_USER?}:${PGDUMP_PASS?}
EOF

chmod 600 ${PGPASSFILE?}
chown postgres:postgres ${PGPASSFILE?}

pgisready ${PGDUMP_DB?} ${PGDUMP_HOST?} ${PGDUMP_PORT?} ${PGDUMP_USER?}

PGDUMP_BASE=/pgdata/${PGDUMP_HOST?}-backups
PGDUMP_PATH=${PGDUMP_BASE?}/$(date +%Y-%m-%d-%H-%M-%S)
mkdir -p ${PGDUMP_PATH?}
chown postgres:postgres ${PGDUMP_PATH?}

output_opts="-f ${PGDUMP_PATH?}/${PGDUMP_FILENAME?}"

echo_info "Dumping to ${output_opts} "

if [[ ${PGDUMP_ALL:-true} == "true" ]]
then
    echo_info "Taking logical backup of all databases.."
    conn_opts+=" -l ${PGDUMP_DB?}"
    ${PGROOT?}/bin/pg_dumpall ${conn_opts?} ${PGDUMP_CUSTOM_OPTS?} ${output_opts?}
else
    echo_info "Taking logical backup of the ${PGDUMP_DB?} database.."
    conn_opts+=" -d ${PGDUMP_DB?}"
    ${PGROOT?}/bin/pg_dump ${conn_opts?} ${PGDUMP_CUSTOM_OPTS?} ${output_opts?}
fi

echo_info "Logical backup completed.  Exiting.."
exit 0
