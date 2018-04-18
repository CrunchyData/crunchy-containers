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

CONF_DIR=/opt/cpm/conf
CONFIGS=/tmp
PGPOOL_PIDFILE=/tmp/pgpool-script.pid

# Cleanup from prior runs
rm -rf /tmp/pgpool.pid
rm -rf /tmp/.s.*

function trap_sigterm() {
    echo_info "Doing trap logic.."
    echo_warn "Clean shutdown of pgPool.."
    kill -SIGINT $(head -1 ${PGPOOL_PIDFILE?})
}

trap 'trap_sigterm' SIGINT SIGTERM

if [[ -f /pgconf/pgpoolconfigdir/pgpool.conf ]]
then
    echo_info "Custom configuration detected.."
    CONFIGS=/pgconf/pgpoolconfigdir
else
    echo_info "No custom configuration detected. Applying default config.."
    cp ${CONF_DIR?}/* ${CONFIGS?}

    env_check_err "PG_PRIMARY_SERVICE_NAME"
    env_check_err "PG_REPLICA_SERVICE_NAME"
    env_check_err "PG_USERNAME"
    env_check_err "PG_PASSWORD"

    # populate template with env vars
    sed -i "s/PG_PRIMARY_SERVICE_NAME/$PG_PRIMARY_SERVICE_NAME/g" ${CONFIGS?}/pgpool.conf
    sed -i "s/PG_REPLICA_SERVICE_NAME/$PG_REPLICA_SERVICE_NAME/g" ${CONFIGS?}/pgpool.conf
    sed -i "s/PG_USERNAME/$PG_USERNAME/g" ${CONFIGS?}/pgpool.conf
    sed -i "s/PG_PASSWORD/$PG_PASSWORD/g" ${CONFIGS?}/pgpool.conf

    echo_info "Populating pool_passwd.."
    /bin/pg_md5 --md5auth --username=${PG_USERNAME?} --config=${CONFIGS?}/pgpool.conf ${PG_PASSWORD?}
fi

echo_info "Starting pgPool.."
/bin/pgpool -n -a ${CONFIGS?}/pool_hba.conf -f ${CONFIGS?}/pgpool.conf  &
echo $! > ${PGPOOL_PIDFILE?}

wait
