#!/bin/bash

# Copyright 2017 Crunchy Data Solutions, Inc.
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

if [ -z "$CCP_IMAGE_TAG" ]; then
	echo "CCP_IMAGE_TAG not set"
	exit 1
fi
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-prometheus:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-promgateway:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-grafana:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-collect:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-pgbadger:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-pgpool:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-watch:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-backup:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-postgres:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-pgbouncer:$CCP_IMAGE_TAG
docker pull registry-dev.crunchydata.com/crunchydata/crunchy-pgadmin4:$CCP_IMAGE_TAG
#docker pull registry-dev.crunchydata.com/crunchydata/crunchy-dba:$CCP_IMAGE_TAG
#docker pull registry-dev.crunchydata.com/crunchydata/crunchy-vacuum:$CCP_IMAGE_TAG
