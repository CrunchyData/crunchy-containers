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

echo "starting pgbouncer container...."

sudo docker stop pgbouncer
sudo docker rm pgbouncer

sudo chcon -Rt svirt_sandbox_file_t `pwd`

sudo docker run \
	-v `pwd`:/pgconf \
	-p 12005:5432 \
	--privileged \
	-v /run/docker.sock:/run/docker.sock \
	-e FAILOVER=true \
	-e SLEEP_TIME=12 \
	-e PG_MASTER_SERVICE=master \
	-e PG_SLAVE_SERVICE=pg-replica \
	-e PG_MASTER_PORT=5432 \
	-e PG_MASTER_USER=masteruser \
	-e PG_DATABASE=postgres \
	--link master:master \
	--name=pgbouncer \
	--hostname=pgbouncer \
	-d crunchydata/crunchy-pgbouncer:centos7-9.5-$CCP_VERSION

