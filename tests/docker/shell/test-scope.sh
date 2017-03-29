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
# test scope
# requires nmap-ncat RPM!
#

docker stop crunchy-grafana
docker stop crunchy-scope

$CCPROOT/examples/standalone/run-scope.sh

sleep 60

PROMETHEUS=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' crunchy-scope`
GRAFANA=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' crunchy-grafana`

curl http://$PROMETHEUS:9090 > /dev/null
rc=$?
echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "prometheus port open"
else
	echo "test scope prometheus FAILED"
	exit $rc
fi
curl http://$PROMETHEUS:9091 > /dev/null
rc=$?
echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "prometheus push gateway port open"
else
	echo "test scope prometheus push gateway FAILED"
	exit $rc
fi

curl http://$GRAFANA:3000 > /dev/null
rc=$?
echo $rc is the grafana rc

if [ 0 -eq $rc ]; then
	echo grafana port open
	echo "test scope passed"
else
	echo "test scope grafana FAILED"
	exit $rc
fi

exit 0
