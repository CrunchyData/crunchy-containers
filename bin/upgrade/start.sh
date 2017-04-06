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

if [[ ! -v "OLD_VERSION" ]]; then
	echo "OLD_VERSION env var is not set, it is required"
	exit 2
fi
if [[ ! -v "NEW_VERSION" ]]; then
	echo "NEW_VERSION env var is not set, it is required"
	exit 2
fi
if [[ ! -v "NEW_DATABASE_NAME" ]]; then
	echo "NEW_DATABASE_NAME env var is not set, it is required"
	exit 2
fi
if [[ ! -v "OLD_DATABASE_NAME" ]]; then
	echo "OLD_DATABASE_NAME env var is not set, it is required"
	exit 2
fi
export OLD_DATA=/pgolddata/$OLD_DATABASE_NAME
if [[ ! -d "OLD_DATA" ]]; then
	echo $OLD_DATA " does not exist and is required"
	exit 2
fi
export NEW_DATA=/pgnewdata/$NEW_DATABASE_NAME
if [[ ! -d "NEW_DATA" ]]; then
	echo $NEW_DATA " does not exist and is required"
	exit 2
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
"9.6")
	echo "setting POSTGRES to " $NEW_VERSION
        export PGROOT=/usr/pgsql-9.6
	;;
"9.5")
	echo "setting POSTGRES to " $NEW_VERSION
        export PGROOT=/usr/pgsql-9.5
	;;
*)
	echo "unsupported NEW_VERSION of " $NEW_VERSION
        exit 2
	;;
esac

echo "setting PGROOT to " $PGROOT

export PATH=/opt/cpm/bin:$PGROOT/bin:$PATH
export LD_LIBRARY_PATH=$PGROOT/lib

env

while true; do
	sleep 1000
done

echo "upgrade has ended!"
