#!/bin/bash

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

echo CCPROOT is $CCPROOT
#
# test backup
#

oc projects openshift

echo "cleaning up any leftovers...."

export PGPASSFILE=/tmp/single-master-pgpass

cleanup() {
$CCPROOT/examples/openshift/single-master/delete.sh
$CCPROOT/examples/openshift/backup-job/delete.sh
# clear out any previous backups
sudo rm -rf /nfsfileshare/single-master
oc delete pod single-master
oc delete service single-master
chmod 777 $PGPASSFILE
/usr/bin/rm $PGPASSFILE
}

cleanup
echo "sleeping for 40 seconds to allow any existing pods/services to terminate"

sleep 40

echo "creating single-master pod..."
$CCPROOT/examples/openshift/single-master/run.sh

echo "sleeping for 40 seconds to allow pods/services to startup"
sleep 40

export IP=`oc describe pod single-master | grep IP | cut -f2 -d':' `
echo $IP " is the IP address"
export MASTERPSW=`oc describe pod single-master | grep MASTER_PASSWORD | cut -f2 -d':' | xargs`
echo "["$MASTERPSW"] is the master password"

echo "creating PGPASSFILE..."
echo "*:*:*:*:"$MASTERPSW > $PGPASSFILE
chmod 400 $PGPASSFILE

psql -h $IP -U master postgres -c 'select now()'

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "connection test passed"
else
	echo "connection test FAILED"
	exit $rc
fi

export IPADDRESS=`hostname --ip-address`

echo "local ip address is " $IPADDRESS

$CCPROOT/examples/openshift/backup-job/run.sh

echo "sleep while backup executes"
sleep 30

sudo find /nfsfileshare/single-master/ -name "postgresql.conf"
rc=$?
echo "final rc is " $rc
if [ 0 -eq $rc ]; then
	echo "backup test passed"
else
	echo "backup test FAILED"
	exit $rc
fi

cleanup
exit 0
