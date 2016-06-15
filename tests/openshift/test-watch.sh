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
cleanup() {
$BUILDBASE/examples/openshift/watchtest/delete.sh
echo "sleeping while cleaning up any leftovers..."
sleep 30
}

#
# test setup
#
cleanup

## create container
$BUILDBASE/examples/openshift/watchtest/run.sh

echo "sleep for 30 while the container starts up..."
sleep 60
echo "deleting the master which triggers the failover..."

oc delete pod ms-master
sleep 60
PODNAME=`oc get pod ms-slave --no-headers | cut -f1 -d' '`
echo $PODNAME " is the new master pod name"
export IP=`oc describe pod $PODNAME | grep IP | cut -f2 -d':' `
echo $IP " is the new master IP address"

export PGPASSFILE=/tmp/master-slave-pgpass
echo "using pgpassfile from master-slave test case...."

echo "should be able to insert into original slave after failover..."
echo "wait for the slave to restart as a new master...."
sleep 30

psql -h $IP -U testuser userdb -c "insert into testtable values ('watch','fromwatch', now())"

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test watch passed"
else
	echo "test watch FAILED"
	exit $rc
fi

echo "performing cleanup..."
cleanup

exit 0
