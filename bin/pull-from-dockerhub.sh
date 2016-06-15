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

if [ -z "$CCP_VERSION" ]; then
	echo "CCP_VERSION not set"
	exit 1
fi
docker pull crunchydata/crunchy-prometheus:$CCP_VERSION
docker pull crunchydata/crunchy-promgateway:$CCP_VERSION
docker pull crunchydata/crunchy-grafana:$CCP_VERSION
docker pull crunchydata/crunchy-dns:$CCP_VERSION
docker pull crunchydata/crunchy-collect:$CCP_VERSION
docker pull crunchydata/crunchy-pgbadger:$CCP_VERSION
docker pull crunchydata/crunchy-pgpool:$CCP_VERSION
docker pull crunchydata/crunchy-watch:$CCP_VERSION
docker pull crunchydata/crunchy-backup:$CCP_VERSION
docker pull crunchydata/crunchy-postgres:$CCP_VERSION
docker pull crunchydata/crunchy-pgbouncer:$CCP_VERSION
