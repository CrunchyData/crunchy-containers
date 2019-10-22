#!/bin/bash

# Copyright 2016 - 2019 Crunchy Data Solutions, Inc.
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

docker push  $CCP_IMAGE_PREFIX/crunchy-prometheus:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-grafana:$CCP_IMAGE_TAG
#docker push  $CCP_IMAGE_PREFIX/crunchy-dns:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-collect:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-pgbadger:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-pgpool:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-backup:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-postgres-gis:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-pgbouncer:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-pgadmin4:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-scheduler:$CCP_IMAGE_TAG
docker push $CCP_IMAGE_PREFIX/crunchy-upgrade:$CCP_IMAGE_TAG
docker push $CCP_IMAGE_PREFIX/crunchy-pgbench:$CCP_IMAGE_TAG
docker push $CCP_IMAGE_PREFIX/crunchy-pgbasebackup-restore:$CCP_IMAGE_TAG
docker push  $CCP_IMAGE_PREFIX/crunchy-postgres-ha:$CCP_IMAGE_TAG
