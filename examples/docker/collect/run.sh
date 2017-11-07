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

echo "make sure basic example is running....starting collect containers..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

export HOSTIP=`hostname --ip-address`

BASIC_VOLUME=basic-example-volume

docker run \
	--privileged=true \
	--volume-driver=local \
	-v $BASIC_VOLUME:/pgdata:ro \
	-e PROM_GATEWAY=http://crunchy-promgateway:9091 \
	-e DATA_SOURCE_NAME="postgresql://postgres:password@basic:5432/postgres?sslmode=disable" \
	-e POSTGRES_EXPORTER_URL="http://localhost:9187/metrics" \
	-e NODE_EXPORTER_URL="http://localhost:9100/metrics" \
	--link basic:basic \
	--link crunchy-promgateway:crunchy-promgateway \
	--name=primary-collect \
	--hostname=primary-collect \
	-d crunchydata/crunchy-collect:$CCP_IMAGE_TAG
