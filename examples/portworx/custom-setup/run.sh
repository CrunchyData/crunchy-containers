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

echo "starting custom container..."

$CCPROOT/examples/envvars.sh

sudo docker stop custom
sudo docker rm custom

sudo docker run \
	--security-opt=label:disable \
	-p $LOCAL_IP:12004:5432 \
	-v custom-conf-volume:/pgconf \
	-v custom-volume:/pgdata \
	-e PG_MODE=master \
	-e PG_MASTER_USER=masteruser \
	-e PG_MASTER_PASSWORD=password \
	-e PG_USER=testuser \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=userdb \
	--name=custom \
	--hostname=custom \
	-d crunchydata/crunchy-postgres:$CCP_IMAGE_TAG

