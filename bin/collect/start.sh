#!/bin/bash

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
