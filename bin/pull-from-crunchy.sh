#!/bin/bash

# Copyright 2018 - 2020 Crunchy Data Solutions, Inc.
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
for CONTAINER in crunchy-upgrade crunchy-pgbadger crunchy-pgpool crunchy-backup crunchy-postgres crunchy-pgbouncer crunchy-pgadmin4 crunchy-pgdump crunchy-pgrestore crunchy-backrest-restore crunchy-pgbench crunchy-pgbasebackup-restore crunchy-postgres-ha
do
	echo $CONTAINER is the container
	docker pull $REG_CCP_IMAGE_PREFIX/$CONTAINER:$CCP_IMAGE_TAG
	docker tag $REG_CCP_IMAGE_PREFIX/$CONTAINER:$CCP_IMAGE_TAG $CCP_IMAGE_PREFIX/$CONTAINER:$CCP_IMAGE_TAG
done

# Now pull the PostGIS containers, which are tagged to include their PostGIS version
for GIS_CONTAINER in crunchy-postgres-gis crunchy-postgres-gis-ha
do
	echo $GIS_CONTAINER is the container
	docker pull $REG_CCP_IMAGE_PREFIX/$CONTAINER:$CCP_POSTGIS_IMAGE_TAG
	docker tag $REG_CCP_IMAGE_PREFIX/$CONTAINER:$CCP_POSTGIS_IMAGE_TAG $CCP_IMAGE_PREFIX/$CONTAINER:$CCP_POSTGIS_IMAGE_TAG
done