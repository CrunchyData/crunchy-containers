#!/bin/bash

# Copyright 2018 Crunchy Data Solutions, Inc.
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
ose_hack

export PG_EXP_HOME=$(find /opt/cpm/bin/ -type d -name 'postgres_exporter*')
export NODE_EXP_HOME=$(find /opt/cpm/bin/ -type d -name 'node_exporter*')
export PG_DIR=$(find /usr/ -type d -name 'pgsql-*')
POSTGRES_EXPORTER_PIDFILE=/tmp/postgres_exporter.pid
NODE_EXPORTER_PIDFILE=/tmp/node_exporter.pid

function trap_sigterm() {
    echo_info "Doing trap logic.."

    echo_warn "Clean shutdown of postgres-exporter.."
    kill -SIGINT $(head -1 $POSTGRES_EXPORTER_PIDFILE)

    echo_warn "Clean shutdown of node-exporter.."
    kill -SIGINT $(head -1 $NODE_EXPORTER_PIDFILE)
}

trap 'trap_sigterm' SIGINT SIGTERM

if [[ -f /conf/queries.yml ]]
then
    echo_info "Custom queries configuration detected.."
    CONFIG_DIR='/conf'
else
    echo_info "No custom queries detected. Applying default configuration.."
    CONFIG_DIR='/opt/cpm/conf'
fi

PG_OPTIONS="--extend.query-path=${CONFIG_DIR?}/queries.yml"

echo_info "Starting node-exporter.."
${NODE_EXP_HOME?}/node_exporter >>/dev/stdout 2>&1 &
echo $! > $NODE_EXPORTER_PIDFILE

# Check that postgres is accepting connections.
echo_info "Waiting for PostgreSQL to be ready.."
while true; do
    ${PG_DIR?}/bin/pg_isready -d ${DATA_SOURCE_NAME}
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 2
done

echo_info "Checking if PostgreSQL is accepting queries.."
while true; do
    ${PG_DIR?}/bin/psql "${DATA_SOURCE_NAME}" -c "SELECT now();" 
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 2
done

echo_info "Starting postgres-exporter.."
${PG_EXP_HOME?}/postgres_exporter ${PG_OPTIONS?} >>/dev/stdout 2>&1 &
echo $! > $POSTGRES_EXPORTER_PIDFILE

wait
