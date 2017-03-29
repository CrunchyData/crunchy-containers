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
# test setup
#

#
# test master
#

$CCPROOT/examples/openshift/single-master/delete.sh
$CCPROOT/examples/openshift/single-master/run.sh

echo "sleeping for 40 seconds to allow pods/services to startup"
sleep 40
export IP=`oc describe pod single-master | grep IP | cut -f2 -d':' `
echo $IP " is the IP address"
export MASTERPSW=`oc describe pod single-master | grep MASTER_PASSWORD | cut -f2 -d':' | xargs`
echo "["$MASTERPSW"] is the master password"

export PGPASSFILE=/tmp/single-master-pgpass
chmod 777 $PGPASSFILE
/usr/bin/rm $PGPASSFILE

echo "creating PGPASSFILE..."
echo "*:*:*:*:"$MASTERPSW > $PGPASSFILE
chmod 400 $PGPASSFILE

psql -h $IP -U master postgres -c 'select now()'

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test master passed"
else
	echo "test master FAILED"
	exit $rc
fi
chmod 777 $PGPASSFILE
/usr/bin/rm $PGPASSFILE
# always delete the pod and service even on a failure

$CCPROOT/examples/openshift/single-master/delete.sh


exit 0
