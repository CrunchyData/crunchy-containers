#bin/bash

# Copyright 2018 Crunchy Data Solutions, Inc.
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

CCP_VERSION=1.7.0
REGISTRY=52.2.93.43:5000
containers="crunchydata/crunchy-vacuum crunchydata/crunchy-prometheus crunchydata/crunchy-promgateway crunchydata/crunchy-grafana crunchydata/crunchy-collect crunchydata/crunchy-pgbadger crunchydata/crunchy-pgpool crunchydata/crunchy-watch crunchydata/crunchy-backup crunchydata/crunchy-postgres"
for i in $containers;
do
	echo $i is the container
	docker tag $i:$CCP_VERSION $REGISTRY/$i:$CCP_VERSION
	docker push $REGISTRY/$i:$CCP_VERSION
done
exit
