#!/bin/bash
# Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
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


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# login into openshift registry
docker login -p $TOKEN -u unused $REG

#	for CONTAINER in "crunchy-postgres" "crunchy-postgres-gis" "crunchy-backup" "crunchy-pgadmin4"
# tag the local image using openshift naming
for CCP_IMAGE_TAG in $CCP_IMAGE_TAG
do
	for CONTAINER in "crunchy-pgadmin4"
	do
		docker tag $CCP_IMAGE_PREFIX/$CONTAINER:$CCP_IMAGE_TAG $REG/$CCP_NAMESPACE/$CONTAINER:$CCP_IMAGE_TAG
		# push the image to openshift
		docker push $REG/$CCP_NAMESPACE/$CONTAINER:$CCP_IMAGE_TAG
	done
done
