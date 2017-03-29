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

oc login -u system:admin
oc projects openshift

$CCPROOT/examples/openshift/metrics/delete.sh

sleep 30

$CCPROOT/examples/openshift/metrics/run.sh

echo "sleeping for 20 seconds to allow pods/services to startup"
sleep 20
export IP=`oc describe pod crunchy-prometheus | grep IP | cut -f2 -d':' `
echo $IP " is the IP address"

curl http://$IP:9090 > /dev/null
rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "prometheus test passed"
else
	echo "prometheus test FAILED"
	exit $rc
fi
export IP=`oc describe pod crunchy-promgateway | grep IP | cut -f2 -d':' `
echo $IP " is the IP address"
curl http://$IP:9091 > /dev/null
rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "prometheus pushgateway test passed"
else
	echo "prometheus pushgateway test FAILED"
	exit $rc
fi
export IP=`oc describe pod crunchy-grafana | grep IP | cut -f2 -d':' `
echo $IP " is the IP address"
curl http://$IP:3000 > /dev/null
rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "grafana test passed"
else
	echo "grafana test FAILED"
	exit $rc
fi

$CCPROOT/examples/openshift/metrics/delete.sh

exit 0
