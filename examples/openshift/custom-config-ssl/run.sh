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


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

CONFDIR=$PV_PATH/custom-config-ssl-pgconf
sudo mkdir $CONFDIR
sudo chown nfsnobody:nfsnobody $CONFDIR
sudo cp $DIR/setup.sql $CONFDIR
sudo cp $DIR/pg_hba.conf $CONFDIR
sudo cp $DIR/postgresql.conf $CONFDIR
sudo chown nfsnobody:nfsnobody $CONFDIR/setup.sql 
sudo chown nfsnobody:nfsnobody $CONFDIR/postgresql.conf 
sudo chown nfsnobody:nfsnobody $CONFDIR/pg_hba.conf
sudo chmod g+r $CONFDIR/setup.sql $CONFDIR/postgresql.conf $CONFDIR/pg_hba.conf

oc create -f $DIR/custom-config-ssl-pvc.json

sudo cp $DIR/ca.crt $CONFDIR
sudo cp $DIR/server.key $CONFDIR
sudo cat server.crt server-intermediate.crt ca.crt > /tmp/server.crt
sudo mv /tmp/server.crt $CONFDIR/server.crt

sudo chown nfsnobody:nfsnobody $CONFDIR/ca.crt 
sudo chown nfsnobody:nfsnobody $CONFDIR/server.key
sudo chown nfsnobody:nfsnobody $CONFDIR/server.crt
sudo chmod 640 $CONFDIR/ca.crt $CONFDIR/server.key $CONFDIR/server.crt
sudo chmod 400 $CONFDIR/server.key

oc process -f $DIR/custom-config-ssl.json -p CCP_IMAGE_PREFIX=$CCP_IMAGE_PREFIX CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
