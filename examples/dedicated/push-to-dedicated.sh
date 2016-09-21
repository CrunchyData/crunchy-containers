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

NS=registry.crunchydata.openshift.com/jeff-project
docker tag  crunchy-prometheus:latest $NS/crunchy-prometheus:$CCP_IMAGE_TAG
docker push  $NS/crunchy-prometheus:$CCP_IMAGE_TAG

docker tag  crunchy-promgateway:latest $NS/crunchy-promgateway:$CCP_IMAGE_TAG
docker push  $NS/crunchy-promgateway:$CCP_IMAGE_TAG

docker tag  crunchy-grafana:latest $NS/crunchy-grafana:$CCP_IMAGE_TAG
docker push  $NS/crunchy-grafana:$CCP_IMAGE_TAG

docker tag  crunchy-collect:latest $NS/crunchy-collect:$CCP_IMAGE_TAG
docker push  $NS/crunchy-collect:$CCP_IMAGE_TAG

docker tag  crunchy-pgbadger:latest $NS/crunchy-pgbadger:$CCP_IMAGE_TAG
docker push  $NS/crunchy-pgbadger:$CCP_IMAGE_TAG

docker tag  crunchy-pgpool:latest $NS/crunchy-pgpool:$CCP_IMAGE_TAG
docker push  $NS/crunchy-pgpool:$CCP_IMAGE_TAG

docker tag  crunchy-watch:latest $NS/crunchy-watch:$CCP_IMAGE_TAG
docker push  $NS/crunchy-watch:$CCP_IMAGE_TAG

docker tag  crunchy-backup:latest $NS/crunchy-backup:$CCP_IMAGE_TAG
docker push  $NS/crunchy-backup:$CCP_IMAGE_TAG

docker tag  crunchy-postgres:latest $NS/crunchy-postgres:$CCP_IMAGE_TAG
docker push  $NS/crunchy-postgres:$CCP_IMAGE_TAG

docker tag  crunchy-pgbouncer:latest $NS/crunchy-pgbouncer:$CCP_IMAGE_TAG
docker push  $NS/crunchy-pgbouncer:$CCP_IMAGE_TAG

