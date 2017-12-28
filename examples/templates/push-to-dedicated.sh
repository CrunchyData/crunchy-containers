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

docker tag  crunchy-prometheus:latest $REG/crunchy-prometheus:$CCP_IMAGE_TAG
docker push  $REG/crunchy-prometheus:$CCP_IMAGE_TAG

docker tag  crunchy-promgateway:latest $REG/crunchy-promgateway:$CCP_IMAGE_TAG
docker push  $REG/crunchy-promgateway:$CCP_IMAGE_TAG

docker tag  crunchy-grafana:latest $REG/crunchy-grafana:$CCP_IMAGE_TAG
docker push  $REG/crunchy-grafana:$CCP_IMAGE_TAG

docker tag  crunchy-collect:latest $REG/crunchy-collect:$CCP_IMAGE_TAG
docker push  $REG/crunchy-collect:$CCP_IMAGE_TAG

docker tag  crunchy-pgbadger:latest $REG/crunchy-pgbadger:$CCP_IMAGE_TAG
docker push  $REG/crunchy-pgbadger:$CCP_IMAGE_TAG

docker tag  crunchy-pgpool:latest $REG/crunchy-pgpool:$CCP_IMAGE_TAG
docker push  $REG/crunchy-pgpool:$CCP_IMAGE_TAG

docker tag  crunchy-watch:latest $REG/crunchy-watch:$CCP_IMAGE_TAG
docker push  $REG/crunchy-watch:$CCP_IMAGE_TAG

docker tag  crunchy-backup:latest $REG/crunchy-backup:$CCP_IMAGE_TAG
docker push  $REG/crunchy-backup:$CCP_IMAGE_TAG

docker tag  crunchy-postgres:latest $REG/crunchy-postgres:$CCP_IMAGE_TAG
docker push  $REG/crunchy-postgres:$CCP_IMAGE_TAG

docker tag  crunchy-pgbouncer:latest $REG/crunchy-pgbouncer:$CCP_IMAGE_TAG
docker push  $REG/crunchy-pgbouncer:$CCP_IMAGE_TAG

docker tag  crunchy-pgadmin4:latest $REG/crunchy-pgadmin4:$CCP_IMAGE_TAG
docker push  $REG/crunchy-pgadmin4:$CCP_IMAGE_TAG
