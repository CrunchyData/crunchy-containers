#!/bin/bash

# Copyright 2017 - 2019 Crunchy Data Solutions, Inc.
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

export NODE_EXP_HOME=$(find /opt/cpm/bin/ -type d -name 'node_exporter*')
NODE_EXPORTER_PIDFILE=/tmp/node_exporter.pid
CONFIG_DIR='/opt/cpm/conf'

function trap_sigterm() {
    echo_info "Doing trap logic.."
    echo_warn "Clean shutdown of node-exporter.."
    kill -SIGINT $(head -1 ${NODE_EXPORTER_PIDFILE?})
}

trap 'trap_sigterm' SIGINT SIGTERM

echo_info "Starting node-exporter.."
${NODE_EXP_HOME?}/node_exporter --path.procfs=/host/proc --path.sysfs=/host/sys >>/dev/stdout 2>&1 &
echo $! > ${NODE_EXPORTER_PIDFILE?}

wait
