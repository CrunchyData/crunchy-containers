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

rm -rf /tmp/pgbouncer.pid

BINDIR=/opt/cpm/bin
CONFDIR=/pgconf

function check_conf() {
        if [ -f $CONFDIR/users.txt ]; then
                echo "users.txt found in " $CONFDIR
	else
                echo "users.txt NOT found in " $CONFDIR
	fi
        if [ -f $CONFDIR/pgbouncer.ini ]; then
                echo "pgbouncer.ini found in " $CONFDIR
		cp $CONFDIR/pgbouncer.ini /tmp
	else
                echo "pgbouncer.ini NOT found in " $CONFDIR
        fi
}

check_conf

if [ -v FAILOVER ]; then
	echo "FAILOVER is set and a watch will be started on the master"
	/opt/cpm/bin/pgbouncer-watch.sh &
fi

pgbouncer /tmp/pgbouncer.ini

#while true; do
#	echo "main sleeping..."
#	sleep 100
#done
