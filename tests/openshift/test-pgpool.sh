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
cleanup() {
$CCPROOT/examples/openshift/master-slave/delete.sh
$CCPROOT/examples/openshift/pgpooltest/delete.sh
echo "sleeping while cleaning up any leftovers..."
sleep 30
}

#
# test setup
#
cleanup


## create container
$CCPROOT/examples/openshift/master-slave/run.sh
echo "give master slave time to start up....60 secs"
sleep 60
$CCPROOT/examples/openshift/pgpooltest/run.sh

echo "sleep for 30 while the container starts up..."
sleep 30

PODNAME=`oc get pod -l name=pgpool-rc --no-headers | cut -f1 -d' '`
echo $PODNAME " is the pgpool pod name"
export IP=`oc describe pod $PODNAME | grep IP | cut -f2 -d':' `
echo $IP " is the IP address"

export PGPASSFILE=/tmp/master-slave-pgpass
echo "using pgpassfile from master-slave test case...."

psql -h $IP -U testuser userdb -c 'select now()'

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test pgpool passed"
else
	echo "test pgpool FAILED"
	exit $rc
fi

echo "performing cleanup..."
cleanup

exit 0
