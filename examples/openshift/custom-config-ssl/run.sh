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

CONFDIR=$CCP_STORAGE_PATH/custom-config-ssl-pgconf
sudo CONFDIR=$CONFDIR mkdir $CONFDIR
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR
sudo CONFDIR=$CONFDIR cp $DIR/setup.sql $CONFDIR
sudo CONFDIR=$CONFDIR cp $DIR/pg_hba.conf $CONFDIR
sudo CONFDIR=$CONFDIR cp $DIR/postgresql.conf $CONFDIR
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/setup.sql 
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/postgresql.conf 
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/pg_hba.conf
sudo CONFDIR=$CONFDIR chmod g+r $CONFDIR/setup.sql $CONFDIR/postgresql.conf $CONFDIR/pg_hba.conf

oc create -f $DIR/custom-config-ssl-pvc.json

sudo CONFDIR=$CONFDIR cp $DIR/ca.crt $CONFDIR
sudo CONFDIR=$CONFDIR cp $DIR/server.key $CONFDIR
sudo cat server.crt server-intermediate.crt ca.crt > /tmp/server.crt
sudo mv /tmp/server.crt $CONFDIR/server.crt

sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/ca.crt 
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/server.key
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/server.crt
sudo CONFDIR=$CONFDIR chmod 640 $CONFDIR/ca.crt $CONFDIR/server.key $CONFDIR/server.crt
sudo CONFDIR=$CONFDIR chmod 400 $CONFDIR/server.key

oc create -f $DIR/service.json
expenv -f $DIR/custom-config-ssl.json | oc create -f -
