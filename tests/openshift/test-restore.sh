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
sudo rm -rf /nfsfileshare/single-master
$CCPROOT/examples/openshift/single-master/delete.sh
$CCPROOT/examples/openshift/master-restore/delete.sh
$CCPROOT/examples/openshift/backup-job/delete.sh
echo "sleeping while cleaning up any leftovers..."
sleep 30
}

#
# test setup
#
cleanup



## create container
$CCPROOT/examples/openshift/single-master/run.sh

echo "sleep for 30 while the container starts up..."
sleep 30

## create backup
$CCPROOT/examples/openshift/backup-job/run.sh
sleep 30

# set the backup to a known and stable name
sudo mv /nfsfilesystem/single-master/2* /nfsfilesystem/single-master/2016-03-28-12-09-28
## create restored container
$CCPROOT/examples/openshift/master-restore/run.sh
sleep 30

export IP=`oc describe pod master-restore | grep IP | cut -f2 -d':' `
echo $IP " is the IP address"
export MASTERPSW=`oc describe pod master-restore | grep MASTER_PASSWORD | cut -f2 -d':' | xargs`
echo "["$MASTERPSW"] is the master password"

export PGPASSFILE=/tmp/master-restore-pgpass
chmod 777 $PGPASSFILE
/usr/bin/rm $PGPASSFILE

echo "creating PGPASSFILE..."
echo "*:*:*:*:"$MASTERPSW > $PGPASSFILE
chmod 400 $PGPASSFILE

oc describe pod master-restore | grep IPAddress

psql -h $IP -U master postgres -c 'select now()'

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test restore passed"
else
	echo "test restore FAILED"
	exit $rc
fi

echo "performing cleanup..."
cleanup

exit 0
