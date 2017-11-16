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

export PATH=$PATH:/usr/pgsql-*/bin

function trap_sigterm() {
	echo "Doing trap logic..."
	kill -SIGINT $PGADMIN_PID
}

trap 'trap_sigterm' SIGINT SIGTERM


# this lets us run initdb and postgres on Openshift
# when it is configured to use random UIDs
function ose_hack() {
        export USER_ID=$(id -u)
        export GROUP_ID=$(id -g)
        envsubst < /opt/cpm/conf/passwd.template > /tmp/passwd
        export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
        export NSS_WRAPPER_PASSWD=/tmp/passwd
        export NSS_WRAPPER_GROUP=/etc/group
}

id
ose_hack
id

echo $PATH is the path
export THISDIR=/pgdata
if [ ! -f "$THISDIR/config_local.py" ]; then
	echo "WARNING: Could not find the mounted configuration files. Using defaults as starting point."
	mkdir $THISDIR
	cp /opt/cpm/conf/config_local.py $THISDIR/
	cp /opt/cpm/conf/pgadmin4.db $THISDIR/
fi

if [ -d "/usr/lib/python2.7/site-packages/pgadmin4-web" ]; then
	cp $THISDIR/config_local.py /usr/lib/python2.7/site-packages/pgadmin4-web/
	python2 /usr/lib/python2.7/site-packages/pgadmin4-web/pgAdmin4.py &
fi
if [ -d "/usr/lib/python2.7/site-packages/pgadmin4" ]; then
	cp $THISDIR/config_local.py /usr/lib/python2.7/site-packages/pgadmin4/
	python2 /usr/lib/python2.7/site-packages/pgadmin4/pgAdmin4.py &
fi

export PGADMIN_PID=$!
echo "Waiting till docker stop or signal is sent to kill pgadmin4..."

wait

while true; do
	echo "Debug sleeping..."
	sleep 1000
done
