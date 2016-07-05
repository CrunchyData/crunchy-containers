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

OSFLAVOR=centos7
PGVERSION=9.5
if [ -z "$CCP_VERSION" ]; then
	echo "CCP_VERSION not set"
	exit 1
fi
docker push  crunchydata/crunchy-prometheus:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-promgateway:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-grafana:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-dns:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-collect:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-pgbadger:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-pgpool:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-watch:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-backup:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-postgres:$OSFLAVOR-$PGVERSION-$CCP_VERSION
docker push  crunchydata/crunchy-pgbouncer:$OSFLAVOR-$PGVERSION-$CCP_VERSION

