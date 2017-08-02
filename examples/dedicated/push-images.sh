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

source $CCPROOT/examples/envvars.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TOKEN=yourtokengoeshere
REG=docker-registry-default.router.default.svc.cluster.local
REG=172.30.240.45:5000
REG=registry.crunchydata.openshift.com
NS=default
NS=jeff2
# login into openshift registry
docker login -p $TOKEN -u unused $REG


#	for CONTAINER in "crunchy-postgres" "crunchy-postgres-gis" "crunchy-backup" "crunchy-pgadmin4"
# tag the local image using openshift naming
for CCP_IMAGE_TAG in "rhel7-9.6-1.5"
do
	for CONTAINER in "crunchy-pgadmin4"
	do
		docker tag crunchydata/$CONTAINER:$CCP_IMAGE_TAG $REG/$NS/$CONTAINER:$CCP_IMAGE_TAG
		# push the image to openshift
		docker push $REG/$NS/$CONTAINER:$CCP_IMAGE_TAG
	done
done
