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

POSTGRES_EXPORTER_PIDFILE=/tmp/postgres_exporter.pid
NODE_EXPORTER_PIDFILE=/tmp/node_exporter.pid
COLLECTSERVER_PIDFILE=/tmp/collectserver.pid

export PATH=$PATH:/opt/cpm/bin

if [ -d /usr/pgsql-10 ]; then
    PGROOT=/usr/pgsql-10
elif [ -d /usr/pgsql-9.6 ]; then
    PGROOT=/usr/pgsql-9.6
elif [ -d /usr/pgsql-9.5 ]; then
	PGROOT=/usr/pgsql-9.5
fi

function trap_sigterm() {
	echo "doing trap logic..."

	echo "Clean shutdown of collectserver..."
	kill -SIGINT $(head -1 $COLLECTSERVER_PIDFILE)

	echo "Clean shutdown of postgres_exporter..."
	kill -SIGINT $(head -1 $POSTGRES_EXPORTER_PIDFILE)

	echo "Clean shutdown of node_exporter..."
	kill -SIGINT $(head -1 $NODE_EXPORTER_PIDFILE)
}

trap 'trap_sigterm' SIGINT SIGTERM

# Check that postgres is accepting connections.
echo "Waiting for postgres to be ready..."
while true; do
	${PGROOT}/bin/pg_isready -d "${DATA_SOURCE_NAME}"
	if [ $? -eq 0 ]; then
		break
	fi
	sleep 2
done

# Check that postgres is accepting queries.
while true; do
	${PGROOT}/bin/psql "${DATA_SOURCE_NAME}" -c "SELECT now();" 
	if [ $? -eq 0 ]; then
		break
	fi
	sleep 2
done

# Start postgres_exporter
echo "Starting postgres_exporter..."
/opt/cpm/bin/postgres_exporter &
echo $! > $POSTGRES_EXPORTER_PIDFILE

sleep 2

# Start node_exporter
echo "Starting node_exporter..."
/opt/cpm/bin/node_exporter*/node_exporter &
echo $! > $NODE_EXPORTER_PIDFILE

sleep 2

# Start collectserver
echo "Starting collectserver..."
/opt/cpm/bin/collectserver \
		-exporter="${POSTGRES_EXPORTER_URL}" \
		-exporter="${NODE_EXPORTER_URL}" \
		-gateway="${PROM_GATEWAY}" &
echo $! > ${COLLECTSERVER_PIDFILE}

wait
