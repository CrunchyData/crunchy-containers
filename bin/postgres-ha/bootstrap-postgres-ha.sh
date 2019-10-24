#!/bin/bash

# Copyright 2016 - 2019 Crunchy Data Solutions, Inc.
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

trap_sigterm() {
    
    echo_warn "Signal trap triggered, beginning shutdown.." | tee -a "${PATRONI_POSTGRESQL_DATA_DIR}"/trap.output

    killall patroni
    echo_warn "Killed Patroni to gracefully shutdown PG" | tee -a "${PATRONI_POSTGRESQL_DATA_DIR}"/trap.output
    
    if [[ ${ENABLE_SSHD} == "true" ]]
    then
        echo_info "Killing SSHD.."
        killall sshd
    fi

    while killall -0 patroni; do
        echo_info "Waiting for Patroni to terminate.."
        sleep 1
    done
    echo_info "Patroni shutdown complete"
}

source /opt/cpm/bin/uid_postgres_no_exec.sh
source /opt/cpm/bin/pre-bootstrap.sh
source /opt/cpm/bin/sshd.sh

if [[ -v PGHA_PRIMARY_HOST ]]
then
    echo_info "Primary host specified, checking if Primary is ready before initializing replica"
    env_check_err "PGHA_PRIMARY_HOST"
    while [[ $(curl --silent "${PGHA_PRIMARY_HOST}:${PGHA_PATRONI_PORT}/master" --stderr - \
        | /opt/cpm/bin/yq r - state 2> /dev/null) != "running" ]] && [[ "${retry_count:=0}" != "${retry_max:=60}" ]]
    do
        echo_info "Primary is not ready, retrying"
        sleep 1
        let "retry_count++"
    done
    if [[ "${retry_count:=0}" == "${retry_max:=60}" ]]
    then
        echo_err "Unable to determine if Primary is ready, aborting initilization of replica"
    fi
    echo_info "Primary is ready, proceeding with initilization of replica"
fi

bootstrap_cmd="$@ /tmp/postgres-ha-bootstrap.yaml"
echo_info "Initializing cluster bootstrap with command: '${bootstrap_cmd}'"
if [[ "$$" == 1 ]]
then
    echo_info "Running Patroni as PID 1"
    exec ${bootstrap_cmd}
else
    echo_info "Patroni will not run as PID 1. Creating signal handler"
    trap 'trap_sigterm' SIGINT SIGTERM
    ${bootstrap_cmd}
fi
