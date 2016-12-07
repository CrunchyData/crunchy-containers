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

echo "make sure basic example is running....starting collect containers..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

# uncomment these lines to override the pg config files with
# your own versions of pg_hba.conf and postgresql.conf
#PGCONF=$HOME/openshift-dedicated-container/pgconf
#sudo chown postgres:postgres $PGCONF
#sudo chmod 0700 $PGCONF
#sudo chcon -Rt svirt_sandbox_file_t $PGCONF
# add this next line to the docker run to override pg config files

export HOSTIP=`hostname --ip-address`

BASIC_VOLUME=basic-example-volume

sudo docker run \
	--privileged=true \
	--volume-driver=local \
	-v $BASIC_VOLUME:/pgdata:ro \
	-e PG_ROOT_PASSWORD=password \
	-e PG_PORT=5432 \
	-e PROM_GATEWAY=http://$HOSTIP:9091 \
	-e HOSTNAME=basic \
	--link basic:basic \
	--name=master-collect \
	--hostname=master-collect \
	-d crunchydata/crunchy-collect:$CCP_IMAGE_TAG
