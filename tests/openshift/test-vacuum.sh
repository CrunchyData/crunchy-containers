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

echo BUILDBASE is $BUILDBASE
#
# test backup
#

oc login -u system:admin
oc projects openshift

echo "cleaning up any leftovers...."

export PGPASSFILE=/tmp/single-master-pgpass

cleanup() {
$BUILDBASE/examples/openshift/vacuum-job/delete.sh
oc delete pod single-master
oc delete service single-master
chmod 777 $PGPASSFILE
/usr/bin/rm $PGPASSFILE
}

cleanup
echo "sleeping for 40 seconds to allow any existing pods/services to terminate"

sleep 40

echo "creating single-master pod..."
oc process -f $BUILDBASE/examples/openshift/master.json |  oc create -f -

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

$BUILDBASE/examples/openshift/vacuum-job/run.sh

echo "sleep while vacuum executes"
sleep 30

PODNAME=`oc get pod --selector="app=vacuum-job" --no-headers| cut -f1 -d' '`
oc describe pod $PODNAME | grep Status: | grep Succeeded 
rc=$?
echo "vacuum rc is " $rc
if [ 0 -eq $rc ]; then
	echo "vacuum test passed"
else
	echo "vacuum test FAILED"
	exit $rc
fi

cleanup
exit 0
