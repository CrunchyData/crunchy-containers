#!/bin/bash  -x

# Copyright 2017 Crunchy Data Solutions, Inc.
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

function trap_sigterm() {
	echo "Doing trap logic..." >> $PGDATA/trap.output

	# Clean shutdowns begin here (force fast mode in case of PostgreSQL < 9.5)
	echo "Clean shut-down of postgres..."
	pg_ctl -w -D $PGDATA -m fast stop

	# Unclean shutdowns begin here (if all else fails)
	if [ -f $PGDATA/postmaster.pid ]; then
		kill -SIGINT $(head -1 $PGDATA/postmaster.pid) >> $PGDATA/trap.output
	fi
}

trap 'trap_sigterm' SIGINT SIGTERM

date

source /opt/cpm/bin/setenv.sh
source check-for-secrets.sh

if [ ! -v PG_MODE ]; then
	echo "PG_MODE environment variable is not set, aborting"
	exit 1
fi

if [ "$PG_MODE" = "master" ]; then
	echo "WARNING:  PG_MODE value of master is deprecated and will be removed in a future release, use PG_MODE value of primary instead."
	export PG_MODE=primary
fi
if [ "$PG_MODE" = "slave" ]; then
	echo "WARNING:  PG_MODE value of slave is deprecated and will be removed in a future release, use PG_MODE value of replica instead."
	export PG_MODE=replica
fi
if [ -v PG_MASTER_HOST ]; then
	echo "WARNING:  PG_MASTER_HOST is deprecated and will be removed in a future release, replace with PG_PRIMARY_HOST"
	export PG_PRIMARY_HOST=$PG_MASTER_HOST
fi
if [ -v PG_MASTER_USER ]; then
	echo "WARNING:  PG_MASTER_USER is deprecated and will be removed in a future release, replace with PG_PRIMARY_USER"
	export PG_PRIMARY_USER=$PG_MASTER_USER
fi
if [ -v PG_MASTER_PASSWORD ]; then
	echo "WARNING:  PG_MASTER_PASSWORD is deprecated and will be removed in a future release, replace with PG_PRIMARY_PASSWORD"
	export PG_PRIMARY_PASSWORD=$PG_MASTER_PASSWORD
fi
if [ -v PG_MASTER_PORT ]; then
	echo "WARNING:  PG_MASTER_PORT is deprecated and will be removed in a future release, replace with PG_PRIMARY_PORT"
	export PG_PRIMARY_PORT=$PG_MASTER_PORT
fi

if [ "$PG_MODE" = "replica" ]; then
	if [ ! -v PG_PRIMARY_HOST ]; then
		echo "PG_PRIMARY_HOST environment variable is not set and required when PG_MODE is replica, aborting"
		exit 1
	fi
fi

if [[ ( ! -v PG_PRIMARY_USER ) && ( ! -v PG_MASTER_USER ) ]]; then
	echo "PG_PRIMARY_USER or PG_MASTER_USER environment variable is not set, aborting"
	exit 1
fi


if [[ ( ! -v PG_PRIMARY_PASSWORD ) && ( ! -v PG_MASTER_PASSWORD ) ]]; then
	echo "PG_PRIMARY_PASSWORD or PG_MASTER_PASSWORD environment variable is not set, aborting"
	exit 1
fi


if [ ! -v PG_USER ]; then
	echo "PG_USER environment variable is not set, aborting"
	exit 1
fi
if [ ! -v PG_PASSWORD ]; then
	echo "PG_PASSWORD environment variable is not set, aborting"
	exit 1
fi
if [ ! -v PG_DATABASE ]; then
	echo "PG_DATABASE environment variable is not set, aborting"
	exit 1
fi
if [ ! -v PG_ROOT_PASSWORD ]; then
	echo "PG_ROOT_PASSWORD environment variable is not set, aborting"
	exit 1
fi

if [[ ( ! -v PG_PRIMARY_PORT ) && ( ! -v PG_MASTER_PORT ) ]]; then
	echo "PG_PRIMARY_PORT or PG_MASTER_PORT environment variable is not set, aborting"
	exit 1
fi

export PG_MODE=$PG_MODE
export PG_PRIMARY_HOST=$PG_PRIMARY_HOST
export PG_PRIMARY_PORT=$PG_PRIMARY_PORT
export PG_PRIMARY_USER=$PG_PRIMARY_USER
export PG_PRIMARY_PASSWORD=$PG_PRIMARY_PASSWORD
export PG_USER=$PG_USER
export PG_PASSWORD=$PG_PASSWORD
export PG_DATABASE=$PG_DATABASE
export PG_ROOT_PASSWORD=$PG_ROOT_PASSWORD


mkdir -p $PGDATA
chmod 0700 $PGDATA

if [[ -v ARCHIVE_MODE ]]; then
	if [ $ARCHIVE_MODE == "on" ]; then
		mkdir -p $PGWAL
		chmod 0700 $PGWAL
		echo "Creating wal directory at " $PGWAL
	fi
fi

## where pg-wrapper is called

function role_discovery() {
	PATH=$PATH:/opt/cpm/bin
	ordinal=${HOSTNAME##*-}
	echo $ordinal is ordinal
	if [ $ordinal -eq 0 ]; then
		kubectl label --overwrite=true pod $HOSTNAME  name=$PG_PRIMARY_HOST
		oc label --overwrite=true pod $HOSTNAME  name=$PG_PRIMARY_HOST
		echo "Setting PG_MODE to primary."
		export PG_MODE=primary
	else
		echo "Setting PG_MODE to replica."
		export PG_MODE=replica
	fi
}

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

function initdb_logic() {
	echo "Doing initdb..."

#	tar xzf /opt/cpm/conf/data.tar.gz --directory=$PGDATA
	cmd="initdb -D $PGDATA "
	if [[ -v PG_LOCALE ]]; then
		cmd+=" --locale="$PG_LOCALE
	fi
        if [[ -v XLOGDIR ]]; then
		if [ $XLOGDIR = "true" ]; then
			echo "XLOGDIR found and true"
			mkdir $PGWAL
			chown postgres:postgres $PGWAL
			if [ -d "$PGWAL" ]; then
                		cmd+=" -X "$PGWAL
			else
				echo "XLOGDIR not found! Using default pg_xlog."
			fi
		fi
        fi
	if [[ -v CHECKSUMS ]]; then
		cmd+=" --data-checksums"
	fi
	cmd+=" > /tmp/initdb.log &> /tmp/initdb.err"

	echo $cmd
	eval $cmd

	echo "Overlaying postgreSQL's configuration with your settings..."
	cp /tmp/postgresql.conf $PGDATA
	cp /opt/cpm/conf/pg_hba.conf /tmp
	sed -i "s/PG_PRIMARY_USER/$PG_PRIMARY_USER/g" /tmp/pg_hba.conf
	cp /tmp/pg_hba.conf $PGDATA

}

function check_for_restore() {
	echo "checking_for_restore"
	ls -l /backup
	if [ ! -f /backup/$BACKUP_PATH/postgresql.conf ]; then
		echo "No backup file found..."
		initdb_logic
	else
		if [ ! -f /pgdata/postgresql.conf ]; then
			echo "Restoring from backup..."
			rsync -a --progress --exclude 'pg_log/*' /backup/$BACKUP_PATH/* $PGDATA
			chmod -R 0700 $PGDATA
		else
			initdb_logic
		fi
	fi
}
function check_for_pitr() {
	echo "Checking for PITR WAL files to recover with..."
	if [ "$(ls -A /recover)" ]; then
		echo "Found non-empty //recover ...assuming a PITR is requested"
		ls -l /recover
		rm $PGDATA/pg_xlog/*0* $PGDATA/pg_xlog/archive_status/*0*
		cp /opt/cpm/conf/pitr-recovery.conf /tmp
		export ENABLE_RECOVERY_TARGET_NAME=#
		export ENABLE_RECOVERY_TARGET_TIME=#
		export ENABLE_RECOVERY_TARGET_XID=#
		if [[ -v RECOVERY_TARGET_NAME ]]; then
			export ENABLE_RECOVERY_TARGET_NAME=" "
		elif [[ -v RECOVERY_TARGET_TIME ]]; then
			export ENABLE_RECOVERY_TARGET_TIME=" "
		elif [[ -v RECOVERY_TARGET_XID ]]; then
			export ENABLE_RECOVERY_TARGET_XID=" "
		fi
		sed -i "s/WAL_DIR/$WAL_DIR/g" /tmp/pitr-recovery.conf
		sed -i "s/ENABLE_RECOVERY_TARGET_NAME/$ENABLE_RECOVERY_TARGET_NAME/g" /tmp/pitr-recovery.conf
		sed -i "s/ENABLE_RECOVERY_TARGET_TIME/$ENABLE_RECOVERY_TARGET_TIME/g" /tmp/pitr-recovery.conf
		sed -i "s/ENABLE_RECOVERY_TARGET_XID/$ENABLE_RECOVERY_TARGET_XID/g" /tmp/pitr-recovery.conf
		sed -i "s/RECOVERY_TARGET_NAME/$RECOVERY_TARGET_NAME/g" /tmp/pitr-recovery.conf
		sed -i "s/RECOVERY_TARGET_TIME/$RECOVERY_TARGET_TIME/g" /tmp/pitr-recovery.conf
		sed -i "s/RECOVERY_TARGET_XID/$RECOVERY_TARGET_XID/g" /tmp/pitr-recovery.conf
		if [[ ! -v RECOVERY_TARGET_INCLUSIVE ]]; then
			RECOVERY_TARGET_INCLUSIVE=true
		fi
		sed -i "s/RECOVERY_TARGET_INCLUSIVE/$RECOVERY_TARGET_INCLUSIVE/g" /tmp/pitr-recovery.conf
		cp /tmp/pitr-recovery.conf $PGDATA/recovery.conf
	fi
}

function fill_conf_file() {
	if [[ -v TEMP_BUFFERS ]]; then
		echo "Overriding TEMP_BUFFERS setting to " + $TEMP_BUFFERS
	else
		TEMP_BUFFERS=8MB
	fi
	if [[ -v MAX_CONNECTIONS ]]; then
		echo "Overriding MAX_CONNECTIONS setting to " + $MAX_CONNECTIONS
	else
		MAX_CONNECTIONS=100
	fi
	if [[ -v SHARED_BUFFERS ]]; then
		echo "Overriding SHARED_BUFFERS setting to " + $SHARED_BUFFERS
	else
		SHARED_BUFFERS=128MB
	fi
	if [[ -v WORK_MEM ]]; then
		echo "Overriding WORK_MEM setting to " + $WORK_MEM
	else
		WORK_MEM=4MB
	fi
	if [[ -v MAX_WAL_SENDERS ]]; then
		echo "Overriding MAX_WAL_SENDERS setting to " + $MAX_WAL_SENDERS
	else
		MAX_WAL_SENDERS=6
	fi

	cp /opt/cpm/conf/postgresql.conf.template /tmp/postgresql.conf

	if [[ -v ARCHIVE_MODE ]]; then
		echo "Overriding ARCHIVE_MODE setting to " + $ARCHIVE_MODE
		cat /opt/cpm/conf/archive-command >> /tmp/postgresql.conf
	else
		ARCHIVE_MODE=off
	fi
	if [[ -v ARCHIVE_TIMEOUT ]]; then
		echo "Overriding ARCHIVE_TIMEOUT setting to " + $ARCHIVE_TIMEOUT
	else
		ARCHIVE_TIMEOUT=0
	fi

	if [ -f /pgconf/pgbackrest.conf ]; then
		echo "Using pgbackrest archive command."
		ARCHIVE_MODE=on
		cat /opt/cpm/conf/backrest-archive-command >> /tmp/postgresql.conf
	fi

	sed -i "s/TEMP_BUFFERS/$TEMP_BUFFERS/g" /tmp/postgresql.conf
	sed -i "s/MAX_CONNECTIONS/$MAX_CONNECTIONS/g" /tmp/postgresql.conf
	sed -i "s/SHARED_BUFFERS/$SHARED_BUFFERS/g" /tmp/postgresql.conf
	sed -i "s/MAX_WAL_SENDERS/$MAX_WAL_SENDERS/g" /tmp/postgresql.conf
	sed -i "s/WORK_MEM/$WORK_MEM/g" /tmp/postgresql.conf
	sed -i "s/ARCHIVE_MODE/$ARCHIVE_MODE/g" /tmp/postgresql.conf
	sed -i "s/ARCHIVE_TIMEOUT/$ARCHIVE_TIMEOUT/g" /tmp/postgresql.conf
}

function create_pgpass() {
cd /tmp
cat >> ".pgpass" <<-EOF
*:*:*:*:${PG_PRIMARY_PASSWORD}
EOF
chmod 0600 .pgpass
}

function waitforpg() {
	export PGPASSFILE=/tmp/.pgpass
	CONNECTED=false
	while true; do
		pg_isready --dbname=$PG_DATABASE --host=$PG_PRIMARY_HOST \
		--port=$PG_PRIMARY_PORT \
		--username=$PG_PRIMARY_USER --timeout=2
		if [ $? -eq 0 ]; then
			echo "The database is ready."
			break
		fi
		sleep 2
	done

	while true; do
		psql -h $PG_PRIMARY_HOST -p $PG_PRIMARY_PORT -U $PG_PRIMARY_USER $PG_DATABASE -f /opt/cpm/bin/readiness.sql
		if [ $? -eq 0 ]; then
			echo "The database is ready."
			CONNECTED=true
			break
		fi

		echo "Attempting pg_isready on primary " $i
		sleep 2
	done

}

function initialize_replica() {
echo "initialize_replica"
rm -rf $PGDATA/*
chmod 0700 $PGDATA

echo "Waiting to give the primary time to start up and register its hostname with Docker before performing the initial backup..."

waitforpg

pg_basebackup -X fetch --no-password --pgdata $PGDATA --host=$PG_PRIMARY_HOST --port=$PG_PRIMARY_PORT -U $PG_PRIMARY_USER

# PostgreSQL recovery configuration.
if [[ -v SYNC_REPLICA ]]; then
	echo "SYNC_REPLICA set"
	APPLICATION_NAME=$SYNC_REPLICA
else
	APPLICATION_NAME=$HOSTNAME
	echo "SYNC_REPLICA not set"
fi
echo $APPLICATION_NAME " is the APPLICATION_NAME being used"

cp /opt/cpm/conf/pgrepl-recovery.conf /tmp
sed -i "s/PG_PRIMARY_USER/$PG_PRIMARY_USER/g" /tmp/pgrepl-recovery.conf
sed -i "s/PG_PRIMARY_HOST/$PG_PRIMARY_HOST/g" /tmp/pgrepl-recovery.conf
sed -i "s/PG_PRIMARY_PORT/$PG_PRIMARY_PORT/g" /tmp/pgrepl-recovery.conf
sed -i "s/APPLICATION_NAME/$APPLICATION_NAME/g" /tmp/pgrepl-recovery.conf
cp /tmp/pgrepl-recovery.conf $PGDATA/recovery.conf
}

#
# the initial start of postgres will create the database
#
function initialize_primary() {
echo "initialize_primary"
if [ ! -f $PGDATA/postgresql.conf ]; then
        echo "pgdata is empty and id is..."
	id
	mkdir -p $PGDATA

	check_for_restore
	check_for_pitr

        echo "Starting database..." >> /tmp/start-db.log

	echo "Temporarily starting database to run setup.sql..."
	pg_ctl -D $PGDATA start

	echo "Waiting for postgreSQL to start..."
	while true; do
                pg_isready \
                --port=$PG_PRIMARY_PORT \
		--host=$HOSTNAME \
		--username=$PG_PRIMARY_USER \
                --timeout=2
                if [ $? -eq 0 ]; then
                        echo "The database is ready for setup.sql."
                        break
                fi
                sleep 2
        done

	if [ -f /pgconf/pgbackrest.conf ]; then
		echo "Creating stanza..."
		pgbackrest --log-path=/backrestrepo --config=/pgconf/pgbackrest.conf --stanza=db stanza-create
	fi


        echo "Loading setup.sql" >> /tmp/start-db.log
	cp /opt/cpm/bin/setup.sql /tmp
	if [ -f /pgconf/setup.sql ]; then
		echo "Using setup.sql from /pgconf"
		cp /pgconf/setup.sql /tmp
	fi
	sed -i "s/PG_PRIMARY_USER/$PG_PRIMARY_USER/g" /tmp/setup.sql
	sed -i "s/PG_PRIMARY_PASSWORD/$PG_PRIMARY_PASSWORD/g" /tmp/setup.sql
	sed -i "s/PG_USER/$PG_USER/g" /tmp/setup.sql
	sed -i "s/PG_PASSWORD/$PG_PASSWORD/g" /tmp/setup.sql
	sed -i "s/PG_DATABASE/$PG_DATABASE/g" /tmp/setup.sql
	sed -i "s/PG_ROOT_PASSWORD/$PG_ROOT_PASSWORD/g" /tmp/setup.sql

	#set PGHOST to use socket in /tmp, we change unix_socket_directory
	#to use /tmp instead of /var/run
	export PGHOST=/tmp
        psql -U postgres < /tmp/setup.sql
	if [ -f /pgconf/audit.sql ]; then
		echo "Using pgaudit_analyze audit.sql from /pgconf"
		psql -U postgres < /pgconf/audit.sql
	fi

	echo "Stopping database after primary initialization..."

	pg_ctl -D $PGDATA --mode=fast stop

	if [[ -v SYNC_REPLICA ]]; then
		echo "Synchronous_standby_names = '"$SYNC_REPLICA"'" >> $PGDATA/postgresql.conf
	fi
fi
}

#
# clean up any old pid file that might have remained
# during a bad shutdown of the container/postgres
#
rm $PGDATA/postmaster.pid
#
# the normal startup of pg
#
#export USER_ID=$(id -u)
#cp /opt/cpm/conf/passwd /tmp
#sed -i "s/USERID/$USER_ID/g" /tmp/passwd
#export LD_PRELOAD=libnss_wrapper.so NSS_WRAPPER_PASSWD=/tmp/passwd  NSS_WRAPPER_GROUP=/etc/group
echo "User id is..."
id

# for stateful set support
case "$PG_MODE" in
	"set")
	role_discovery
	;;
esac

ose_hack

fill_conf_file

case "$PG_MODE" in
	"replica"|"slave")
	echo "Working on replica..."
	create_pgpass
	export PGPASSFILE=/tmp/.pgpass
	if [ ! -f $PGDATA/postgresql.conf ]; then
		initialize_replica
	fi
	;;
	"primary"|"master")
	echo "Working on primary..."
	initialize_primary
	;;
	*)
	echo "FATAL:  PG_MODE is not an accepted value...check your PG_MODE environment variable valid values are (primary, replica)"
	;;
esac


if [ -f /pgconf/postgresql.conf ]; then
       	echo "pgconf postgresql.conf is being used"
	postgres -c config_file=/pgconf/postgresql.conf -c hba_file=/pgconf/pg_hba.conf -D $PGDATA  &
else
	postgres -D $PGDATA  &
fi

date

if [[ -v PGAUDIT_ANALYZE ]]; then
	echo "pgaudit_analyze will be started up..."
	pgaudit_analyze $PGDATA/pg_log --user=postgres --log-file /tmp/pgaudit_analyze.log &
fi

# We will wait indefinitely until "docker stop [container_id]"
# When that happens, we route to the "trap_sigterm" function above
wait

echo "Exiting...at end"
