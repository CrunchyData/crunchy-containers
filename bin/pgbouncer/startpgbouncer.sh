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

PGBOUNCER_PID=/tmp/pgbouncer-script.pid
CONF_DIR=/pgconf/bouncerconfig

# Cleanup previous deployments
rm -rf /tmp/pgbouncer.pid

function trap_sigterm() {
    echo_warn "Doing trap logic..."
    echo_info "Clean shutdown of pgBouncer.."
    kill -SIGINT $(head -1 ${PGBOUNCER_PID?})
}

trap 'trap_sigterm' SIGINT SIGTERM

if [[ -f ${CONF_DIR?}/users.txt ]]
then
    echo_info "Custom users.txt file detected.."
fi

if [[ -f ${CONF_DIR?}/pgbouncer.ini ]]
then
    echo_info "Custom pgbouncer.ini file detected.."
else
    echo_info "No custom pgbouncer.ini detected. Applying default config.."
    cp /opt/cpm/conf/pgbouncer.ini ${CONF_DIR?}/pgbouncer.ini
fi

if [[ -v FAILOVER ]]
then
    echo_warn "FAILOVER environment variable set. Failover with pgBouncer is not supported."
fi

echo_info "Starting pgBouncer.."
pgbouncer ${CONF_DIR?}/pgbouncer.ini -u daemon &
echo $! > ${PGBOUNCER_PID?}

wait
