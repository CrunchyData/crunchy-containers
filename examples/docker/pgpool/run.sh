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

echo "starting pgpool container...."

sudo docker stop pgpool
sudo docker rm pgpool

sudo docker run \
	-p 12003:5432 \
	--link master:master \
	--link replica:replica \
	-e PG_MASTER_SERVICE_NAME=master \
	-e PG_SLAVE_SERVICE_NAME=replica \
	-e PG_USERNAME=testuser \
	-e PG_PASSWORD=password \
	-e PG_DATABASE=postgres \
	--name=pgpool \
	--hostname=pgpool \
	-d crunchydata/crunchy-pgpool:$CCP_IMAGE_TAG

