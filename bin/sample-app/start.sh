#!/bin/bash

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
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

export PATH=$PATH:/opt/cpm/bin
export PGROOT=$(find /usr/ -type d -name 'pgsql-*')
export PIDFILE=/tmp/sample-app.pid

function trap_sigterm() {
    echo_info "Doing trap logic.."
    echo_warn "Clean shut-down of Sample Application server.."
    kill -SIGINT $(head -1 $PIDFILE)
}

trap 'trap_sigterm' SIGINT SIGTERM

mkdir -p /tmp/static
cp /opt/cpm/conf/main.css /tmp/static/main.css

env_check_err 'PG_USER'
env_check_err 'PG_PASSWORD'
env_check_err 'PG_DATABASE'
env_check_err 'PG_HOSTNAME'
export PG_PORT="${PG_PORT:-5432}"

touch /tmp/.pgpass
chmod 600 /tmp/.pgpass
echo "${PG_HOSTNAME}:${PG_PORT}:*:${PG_USER}:${PG_PASSWORD}" > /tmp/.pgpass
export PGPASSFILE=/tmp/.pgpass

pgisready ${PG_DATABASE} ${PG_HOSTNAME} ${PG_PORT} ${PG_USER}

echo_info "Starting Sample Application.."
/opt/cpm/bin/sample-app &
echo $! > $PIDFILE

wait
