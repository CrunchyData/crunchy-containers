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

echo "starting vacuum container..."

docker stop crunchy-vacuum-job
docker rm crunchy-vacuum-job

sudo docker run \
	-e VAC_FULL="true" \
	-e JOB_HOST="master" \
	-e VAC_ANALYZE="true" \
	-e VAC_ALL="true" \
	-e VAC_VERBOSE="true" \
	-e VAC_FREEZE="true" \
	-e VAC_TABLE="testtable" \
	-e PG_USER="testuser" \
	-e PG_PORT="5432" \
	-e PG_PASSWORD="password" \
	-e PG_DATABASE="userdb" \
	--link master:master \
	--name=crunchy-vacuum-job \
	--hostname=crunchy-vacuum-job \
	-d crunchydata/crunchy-vacuum:latest

