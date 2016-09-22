#!/bin/bash -x

# Copyright 2016 Crunchy Data Solutions, Inc.
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

#
# start pg, will initdb if /pgdata is empty as a way to bootstrap
#

source /opt/cpm/bin/setenv.sh

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
	echo "doing initdb...."

#	tar xzf /opt/cpm/conf/data.tar.gz --directory=$PGDATA
	cmd="initdb -D $PGDATA "
	if [[ -v PG_LOCALE ]]; then
		cmd+=" --locale="$PG_LOCALE
	fi
	if [[ -v CHECKSUMS ]]; then
		cmd+=" --data-checksums"
	fi
	cmd+=" > /tmp/initdb.log &> /tmp/initdb.err"

	echo $cmd
	eval $cmd

	echo "overlay pg config with your settings...."
	cp /tmp/postgresql.conf $PGDATA
	cp /opt/cpm/conf/pg_hba.conf /tmp
	sed -i "s/PG_MASTER_USER/$PG_MASTER_USER/g" /tmp/pg_hba.conf
	cp /tmp/pg_hba.conf $PGDATA
}

function check_for_restore() {
	echo "checking_for_restore"
	ls -l /backup
	if [ ! -f /backup/$BACKUP_PATH/postgresql.conf ]; then
		echo "no backup file found..."
		initdb_logic
	else
		if [ ! -f /pgdata/postgresql.conf ]; then
			echo "doing restore from backup...."
			rsync -a --progress --exclude 'pg_log/*' /backup/$BACKUP_PATH/* $PGDATA
			chmod -R 0700 $PGDATA
		else
			initdb_logic
		fi
	fi
}
function check_for_pitr() {
	echo "checking for PITR WAL files to recover with.."
	if [ "$(ls -A /pgarchive)" ]; then
		echo "found non-empty /pgarchive ...assuming a PITR is requested"
		ls -l /pgarchive
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
		echo "overriding TEMP_BUFFERS setting to " + $TEMP_BUFFERS
	else
		TEMP_BUFFERS=8MB
	fi
	if [[ -v MAX_CONNECTIONS ]]; then
		echo "overriding MAX_CONNECTIONS setting to " + $MAX_CONNECTIONS
	else
		MAX_CONNECTIONS=100
	fi
	if [[ -v SHARED_BUFFERS ]]; then
		echo "overriding SHARED_BUFFERS setting to " + $SHARED_BUFFERS
	else
		SHARED_BUFFERS=128MB
	fi
	if [[ -v WORK_MEM ]]; then
		echo "overriding WORK_MEM setting to " + $WORK_MEM
	else
		WORK_MEM=4MB
	fi
	if [[ -v MAX_WAL_SENDERS ]]; then
		echo "overriding MAX_WAL_SENDERS setting to " + $MAX_WAL_SENDERS
	else
		MAX_WAL_SENDERS=6
	fi
	if [[ -v ARCHIVE_MODE ]]; then
		echo "overriding ARCHIVE_MODE setting to " + $ARCHIVE_MODE
	else
		ARCHIVE_MODE=off
	fi
	if [[ -v ARCHIVE_TIMEOUT ]]; then
		echo "overriding ARCHIVE_TIMEOUT setting to " + $ARCHIVE_TIMEOUT
	else
		ARCHIVE_TIMEOUT=60
	fi

	cp /opt/cpm/conf/postgresql.conf.template /tmp/postgresql.conf
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
*:*:*:*:${PG_MASTER_PASSWORD}
EOF
chmod 0600 .pgpass
}

function waitforpg() {
	CONNECTED=false
	for i in `seq 1 40`;
	do
		pg_isready --dbname=$PG_DATABASE --host=$PG_MASTER_HOST \
			--port=$PG_MASTER_PORT \
			--username=$PG_MASTER_USER --timeout=2
		if [ $? -eq 0 ]; then
			echo "database is ready"
			CONNECTED=true
			break
		fi

		echo "trying pg_isready on master " $i
	done
	if [ "$CONNECTED" = false ]; then
		echo "could not connect"
	fi
}

function initialize_replica() {
echo "initialize_replica"
rm -rf $PGDATA/*
chmod 0700 $PGDATA

echo "waiting to give the master time to start up before performing the initial backup...."
sleep 60
waitforpg

pg_basebackup -x --no-password --pgdata $PGDATA --host=$PG_MASTER_HOST --port=$PG_MASTER_PORT -U $PG_MASTER_USER

# PostgreSQL recovery configuration.
if [[ -v SYNC_SLAVE ]]; then
	echo "SYNC_SLAVE set"
	APPLICATION_NAME=$SYNC_SLAVE
else
	APPLICATION_NAME=$HOSTNAME
	echo "SYNC_SLAVE not set"
fi
echo $APPLICATION_NAME " is the APPLICATION_NAME being used"

cp /opt/cpm/conf/pgrepl-recovery.conf /tmp
sed -i "s/PG_MASTER_USER/$PG_MASTER_USER/g" /tmp/pgrepl-recovery.conf
sed -i "s/PG_MASTER_HOST/$PG_MASTER_HOST/g" /tmp/pgrepl-recovery.conf
sed -i "s/PG_MASTER_PORT/$PG_MASTER_PORT/g" /tmp/pgrepl-recovery.conf
sed -i "s/APPLICATION_NAME/$APPLICATION_NAME/g" /tmp/pgrepl-recovery.conf
cp /tmp/pgrepl-recovery.conf $PGDATA/recovery.conf
}

#
# the initial start of postgres will create the database
#
function initialize_master() {
echo "initialize_master"
if [ ! -f $PGDATA/postgresql.conf ]; then
        echo "pgdata is empty and id is..."
	id
	mkdir -p $PGDATA

	check_for_restore
	if [ "$(ls -A /pgarchive)" ]; then
		echo "found non-empty /pgarchive ...assuming a PITR is requested...removing any pg_xlog files"
		rm $PGDATA/pg_xlog/*0* $PGDATA/pg_xlog/archive_status/*0*
	fi

        echo "starting db" >> /tmp/start-db.log
	if [ -f /pgconf/postgresql.conf ]; then
        	echo "pgconf postgresql.conf is being used with PGDATA=" $PGDATA
		postgres -c config_file=/pgconf/postgresql.conf -c hba_file=/pgconf/pg_hba.conf -D $PGDATA &
	else
        	echo "normal postgresql.conf is being used"
		pg_ctl -D $PGDATA start
	fi

        sleep 3

        echo "loading setup.sql" >> /tmp/start-db.log
	cp /opt/cpm/bin/setup.sql /tmp
	if [ -f /pgconf/setup.sql ]; then
		echo "using setup.sql from /pgconf"
		cp /pgconf/setup.sql /tmp
	fi
	sed -i "s/PG_MASTER_USER/$PG_MASTER_USER/g" /tmp/setup.sql
	sed -i "s/PG_MASTER_PASSWORD/$PG_MASTER_PASSWORD/g" /tmp/setup.sql
	sed -i "s/PG_USER/$PG_USER/g" /tmp/setup.sql
	sed -i "s/PG_PASSWORD/$PG_PASSWORD/g" /tmp/setup.sql
	sed -i "s/PG_DATABASE/$PG_DATABASE/g" /tmp/setup.sql
	sed -i "s/PG_ROOT_PASSWORD/$PG_ROOT_PASSWORD/g" /tmp/setup.sql

	echo "sleep 7 till postgres is ready"
	sleep 7

	#set PGHOST to use socket in /tmp, we change unix_socket_directory
	#to use /tmp instead of /var/run
	export PGHOST=/tmp
        psql -U postgres < /tmp/setup.sql

	pg_ctl -D $PGDATA stop

	if [[ -v SYNC_SLAVE ]]; then
		echo "synchronous_standby_names = '" $SYNC_SLAVE "'" >> $PGDATA/postgresql.conf
	fi
	check_for_pitr
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
echo "user id is..."
id

ose_hack

fill_conf_file


case "$PG_MODE" in 
	"slave")
	echo "working on slave"
	create_pgpass
	export PGPASSFILE=/tmp/.pgpass
	if [ ! -f $PGDATA/postgresql.conf ]; then
		initialize_replica
	fi
	;;
	"master")
	echo "working on master..."
	initialize_master
	;;
	*)
	echo "FATAL:  PG_MODE is not an accepted value...check your PG_MODE env var"
	;;
esac

if [ -f /pgconf/postgresql.conf ]; then
       	echo "pgconf postgresql.conf is being used"
	postgres -c config_file=/pgconf/postgresql.conf -c hba_file=/pgconf/pg_hba.conf -D $PGDATA 
else
	postgres -D $PGDATA 
fi

