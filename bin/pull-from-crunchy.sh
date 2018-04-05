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
REG_CCP_IMAGE_PREFIX=registry.crunchydata.com/crunchydata
for CONTAINER in crunchy-prometheus crunchy-dba crunchy-vacuum crunchy-upgrade crunchy-grafana crunchy-collect crunchy-pgbadger crunchy-pgpool crunchy-watch crunchy-backup crunchy-postgres crunchy-postgres-gis crunchy-pgbouncer crunchy-pgadmin4 crunchy-pgdump crunchy-pgrestore crunchy-backrest-restore
do
	echo $CONTAINER is the container
	docker pull $REG_CCP_IMAGE_PREFIX/$CONTAINER:$CCP_IMAGE_TAG
	docker tag $REG_CCP_IMAGE_PREFIX/$CONTAINER:$CCP_IMAGE_TAG $CCP_IMAGE_PREFIX/$CONTAINER:$CCP_IMAGE_TAG
done
