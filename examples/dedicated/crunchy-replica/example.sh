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

# this is an example of creating a postgres database using
# the crunchy-master template from the CLI

source $CCPROOT/examples/envvars.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PROJECT=jeff-project

#oc process --parameters -n $PROJECT crunchy-replica

oc process -n $PROJECT crunchy-replica \
	-p CCP_IMAGE_TAG=rhel7-9.6-1.3.0 \
	-p CCP_IMAGE_PREFIX=172.30.149.135:5000/default \
	-p CCP_IMAGE_NAME=crunchy-postgres \
	-p SERVICE_NAME=replica \
	-p PG_MASTER_HOST=master \
	-p PG_MASTER_PORT=5432 \
	-p PG_MASTER_USER=master \
	-p PG_MASTER_PASSWORD=password \
	-p PVC_NAME=replica-pvc \
	-p PVC_SIZE=300M \
	-p PVC_ACCESS_MODE=ReadWriteMany 
	| oc create -f -
