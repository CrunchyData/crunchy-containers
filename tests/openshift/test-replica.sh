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
# test master slave replication
#

oc login -u system:admin
oc projects openshift


$CCPROOT/examples/openshift/master-slave/delete.sh

$CCPROOT/examples/openshift/master-slave/run.sh

SLEEP=50
echo "sleeping for " $SLEEP " seconds to allow pods/services to startup"
sleep $SLEEP

export MASTERIP=`oc describe pod ms-master | grep IP | cut -f2 -d':' `
export SLAVEIP=`oc describe pod ms-slave | grep IP | cut -f2 -d':' `
echo $MASTERIP " is the master IP address"
echo $SLAVEIP " is the slave IP address"
export MASTERPSW=`oc describe pod ms-master | grep MASTER_PASSWORD | cut -f2 -d':' | xargs`
echo "["$MASTERPSW"] is the master password"

export PGPASSFILE=/tmp/master-slave-pgpass
chmod 777 $PGPASSFILE
/usr/bin/rm $PGPASSFILE

echo "creating PGPASSFILE..."
echo "*:*:*:*:"$MASTERPSW > $PGPASSFILE
chmod 400 $PGPASSFILE


psql -h $MASTERIP -U master postgres -c 'select now()'

rc=$?

echo $rc is the master rc

echo "sleeping till slave is ready..."

sleep $SLEEP

psql -h $SLAVEIP -U master postgres -c 'select now()'

slaverc=$?
echo $slaverc is the slave rc

resultrc=0

if [ 0 -eq $rc ]; then
	echo "test master slave master test passed"
else
	echo "test master slave master test FAILED"
	resultrc=2
fi
if [ 0 -eq $slaverc ]; then
	echo "test master slave slave test passed"
else
	echo "test master slave slave test FAILED"
	resultrc=2
fi

$CCPROOT/examples/openshift/master-slave/delete.sh

exit $resultrc

