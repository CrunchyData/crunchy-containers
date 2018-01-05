#!/bin/bash

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

docker push  crunchydata/crunchy-prometheus:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-promgateway:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-grafana:$CCP_IMAGE_TAG
#docker push  crunchydata/crunchy-dns:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-collect:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-pgbadger:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-pgpool:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-watch:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-backup:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-postgres:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-postgres-gis:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-pgbouncer:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-pgadmin4:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-vacuum:$CCP_IMAGE_TAG
docker push  crunchydata/crunchy-dba:$CCP_IMAGE_TAG
