#!/bin/bash 

# Copyright 2015 Crunchy Data Solutions, Inc.
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

export PIDFILE=/tmp/badgerserver.pid

function trap_sigterm() {
        echo "doing trap logic..."

        echo "Clean shut-down of badgerserver ..."

        kill -SIGINT $(head -1 $PIDFILE)

}

trap 'trap_sigterm' SIGINT SIGTERM

if [ -v BADGER_TARGET ]; then
	echo "BADGER_TARGET set for standalone environment"
	export BADGER_TARGET=$BADGER_TARGET
fi

export PATH=$PATH:/opt/cpm/bin

/opt/cpm/bin/badgerserver &
echo $! > $PIDFILE

echo "waiting for badgerserver to catch signal..."

wait

