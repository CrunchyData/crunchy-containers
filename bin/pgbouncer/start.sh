#!/bin/bash

# Copyright 2016 - 2020 Crunchy Data Solutions, Inc.
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

source /opt/cpm/bin/common_lib.sh
enable_debugging


PGBOUNCER_PID=/tmp/pgbouncer-script.pid
CONF_DIR=/pgconf

# Cleanup previous deployments
rm -rf /tmp/pgbouncer.pid

function trap_sigterm() {
    echo_warn "Doing trap logic..."
    echo_info "Clean shutdown of pgBouncer.."
    kill -SIGINT $(head -1 ${PGBOUNCER_PID?})
}

trap 'trap_sigterm' SIGINT SIGTERM

touch /tmp/.pgpass
chmod 600 /tmp/.pgpass

if [[ -f ${CONF_DIR?}/users.txt ]]
then
    echo_info "Custom users.txt file detected.."
else
    echo_info "No custom users.txt detected.  Apply default config.."
    cp /opt/cpm/conf/users.txt ${CONF_DIR?}/users.txt
    env_check_err "PGBOUNCER_PASSWORD"
    sed -i "s/PGBOUNCER_PASSWORD/${PGBOUNCER_PASSWORD?}/g" ${CONF_DIR?}/users.txt
fi

if [[ -f ${CONF_DIR?}/pgbouncer.ini ]]
then
    echo_info "Custom pgbouncer.ini file detected.."
else
    echo_info "No custom pgbouncer.ini detected.  Applying default config.."
    touch ${CONF_DIR?}/pgbouncer.ini

    env_check_err "PG_SERVICE"

    set -a
    : "${DEFAULT_POOL_SIZE:-20}"
    : "${MAX_CLIENT_CONN:-100}"
    : "${MAX_DB_CONNECTIONS:-0}"
    : "${MIN_POOL_SIZE:-0}"
    : "${POOL_MODE:-session}"
    : "${RESERVE_POOL_SIZE:-0}"
    : "${RESERVE_POOL_TIMEOUT:-5}"
    : "${QUERY_TIMEOUT:-0}"
    : "${IGNORE_STARTUP_PARAMETERS:-extra_float_digits}"
    : "${PG_PORT:-5432}"
    set +a
    envsubst < /opt/cpm/conf/pgbouncer.ini > ${CONF_DIR?}/pgbouncer.ini

    echo "${PG_SERVICE}:${PG_PORT:-5432}:*:pgbouncer:${PGBOUNCER_PASSWORD}" >> /tmp/.pgpass
fi

export PGPASSFILE=/tmp/.pgpass

echo_info "Starting pgBouncer.."
pgbouncer ${CONF_DIR?}/pgbouncer.ini &
echo $! > ${PGBOUNCER_PID?}

wait
