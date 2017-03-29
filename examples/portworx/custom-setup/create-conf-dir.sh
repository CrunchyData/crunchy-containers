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

echo "creating conf dir in custom-conf volume..."

docker stop custom-setup custom-ls
docker rm custom-setup custom-ls

CONF_DIR=/tmp/setupsql-conf
sudo rm -rf $CONF_DIR
sudo mkdir -p $CONF_DIR
sudo cp $CCPROOT/examples/portworx/custom-setup/setup.sql $CONF_DIR
sudo chown postgres:postgres $CONF_DIR
sudo chcon -Rt svirt_sandbox_file_t $CONF_DIR
sudo chmod 0700 $CONF_DIR

docker run \
	--security-opt=label:disable \
	-v custom-conf-volume:/pgconf \
	-v $CONF_DIR:/myhostdir \
	--name=custom-setup \
	--hostname=custom-setup \
	crunchydata/crunchy-postgres:centos7-9.5-$CCP_VERSION cp /myhostdir/setup.sql /pgconf

docker run \
	--security-opt=label:disable \
	-v custom-conf-volume:/pgconf \
	--name=custom-ls \
	--hostname=custom-ls \
	crunchydata/crunchy-postgres:centos7-9.5-$CCP_VERSION find /pgconf

docker rm custom-setup custom-ls
