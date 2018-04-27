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
export PIDFILE=/tmp/badgerserver.pid

function trap_sigterm() {
    echo_info "Doing trap logic.."
    echo_warn "Clean shut-down of pgBadger server.."
    kill -SIGINT $(head -1 $PIDFILE)
}

trap 'trap_sigterm' SIGINT SIGTERM

env_check_info "BADGER_TARGET" "Overriding BADGER_TARGET environment variable and setting to ${BADGER_TARGET}."

echo_info "Starting pgBadger server.."
/opt/cpm/bin/badgerserver &
echo $! > $PIDFILE

wait
