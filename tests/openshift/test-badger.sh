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
# test badger
#

oc login -u system:admin
oc projects openshift

$CCPROOT/examples/openshift/badger/delete.sh

echo "sleeping for 10 seconds to allow any existing pods/services to terminate"
sleep 10

$CCPROOT/examples/openshift/badger/run.sh


echo "sleeping for 10 seconds to allow pods/services to startup"
sleep 10
export IP=`oc describe pod badger-example | grep IP | cut -f2 -d':' `
curl http://$IP:10000/api/badgergenerate > /dev/null

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test badger passed"
else
	echo "test badger FAILED"
	exit $rc
fi

$CCPROOT/examples/openshift/badger/delete.sh
exit 0
