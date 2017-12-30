#!/bin/bash -x

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

#
# start the upgrade job
#
# the service looks for the following env vars to be set by
# the cpm-admin that provisioned us
#
# /pgolddata is a volume that gets mapped into this container
# /pgnewdata is a volume that gets mapped into this container
# $OLD_VERSION (e.g. 9.5) 
# $NEW_VERSION (e.g. 9.6)
#

function trap_sigterm() {
        echo "doing trap logic..." >> $PGDATA/trap.output
	kill -SIGINT `head -1 $PGDATA/postmaster.pid` >> $PGDATA/trap.output
}

trap 'trap_sigterm' SIGINT SIGTERM

if [[ ! -v "OLD_VERSION" ]]; then
	echo "OLD_VERSION env var is not set, it is required"
	exit 2
fi
if [[ ! -v "NEW_VERSION" ]]; then
	echo "NEW_VERSION env var is not set, it is required"
	exit 2
fi
if [[ ! -v "OLD_DATABASE_NAME" ]]; then
	echo "OLD_DATABASE_NAME env var is not set, it is required"
	exit 2
fi
if [[ ! -v "NEW_DATABASE_NAME" ]]; then
	echo "NEW_DATABASE_NAME env var is not set, it is required"
	exit 2
fi

export PGDATAOLD=/pgolddata/$OLD_DATABASE_NAME
if [[ ! -d "$PGDATAOLD" ]]; then
	echo $PGDATAOLD " does not exist and is required"
#	exit 2
fi
export PGDATANEW=/pgnewdata/$NEW_DATABASE_NAME
if [[ ! -d "$PGDATANEW" ]]; then
	echo $PGDATANEW " does not exist and is required"
#	exit 2
fi

function ose_hack() {
        export USER_ID=$(id -u)
        export GROUP_ID=$(id -g)
        envsubst < /opt/cpm/conf/passwd.template > /tmp/passwd
        export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
        export NSS_WRAPPER_PASSWD=/tmp/passwd
        export NSS_WRAPPER_GROUP=/etc/group
}


ose_hack

# set the postgres binary to match the NEW_VERSION

case $NEW_VERSION in
"10")
	echo "setting PGBINNEW to " $NEW_VERSION
	export PGBINNEW=/usr/pgsql-10/bin
	export LD_LIBRARY_PATH=/usr/pgsql-10/lib
	;;
"9.6")
	echo "setting PGBINNEW to " $NEW_VERSION
	export PGBINNEW=/usr/pgsql-9.6/bin
	export LD_LIBRARY_PATH=/usr/pgsql-9.6/lib
	;;
"9.5")
	echo "setting PGBINNEW to " $NEW_VERSION
	export PGBINNEW=/usr/pgsql-9.5/bin
	export LD_LIBRARY_PATH=/usr/pgsql-9.5/lib
	;;
*)
	echo "unsupported NEW_VERSION of " $NEW_VERSION
        exit 2
	;;
esac
case $OLD_VERSION in
"9.6")
	echo "setting PGBINOLD to " $OLD_VERSION
	export PGBINOLD=/usr/pgsql-9.6/bin
	;;
"9.5")
	echo "setting PGBINOLD to " $OLD_VERSION
	export PGBINOLD=/usr/pgsql-9.5/bin
	;;
*)
	echo "unsupported OLD_VERSION of " $OLD_VERSION
        exit 2
	;;
esac


export PATH=/opt/cpm/bin:$PGBINNEW:$PATH

env

# create a clean new data directory
options=" "
if [[ -v PG_LOCALE ]]; then
	options+=" --locale="$PG_LOCALE
fi
if [[ -v XLOGDIR ]]; then
	if [ -d "$XLOGDIR" ]; then
		options+=" --X "$XLOGDIR
	else
		echo "XLOGDIR not found! Using default pg_xlog"
	fi
fi
if [[ -v CHECKSUMS ]]; then
	options+=" --data-checksums"
fi

echo "using " $options " for initdb options"
$PGBINNEW/initdb -D $PGDATANEW $options

# get the old config files and use those in the new database
cp $PGDATAOLD/postgresql.conf  $PGDATANEW
cp $PGDATAOLD/pg_hba.conf  $PGDATANEW

# remove the old postmaster.pid 
rm $PGDATAOLD/postmaster.pid

# changing to /tmp is necessary since pg_upgrade has to have write access
cd /tmp

$PGBINNEW/pg_upgrade
rc=$?
if (( $rc ==  0 )); then
	echo "Successfully performed upgrade"
else
	echo "error in upgrade rc=" $rc
fi

exit $rc

#while true; do
#	sleep 1000
#done

#wait


