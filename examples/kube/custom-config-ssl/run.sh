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

$DIR/cleanup.sh

CONFDIR=$CCP_STORAGE_PATH/custom-config-ssl-pgconf
sudo CONFDIR=$CONFDIR mkdir $CONFDIR
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR
sudo CONFDIR=$CONFDIR cp $DIR/configs/setup.sql $CONFDIR
sudo CONFDIR=$CONFDIR cp $DIR/configs/pg_hba.conf $CONFDIR
sudo CONFDIR=$CONFDIR cp $DIR/configs/postgresql.conf $CONFDIR
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/setup.sql
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/postgresql.conf
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/pg_hba.conf
sudo CONFDIR=$CONFDIR chmod g+r $CONFDIR/setup.sql $CONFDIR/postgresql.conf $CONFDIR/pg_hba.conf

sudo CONFDIR=$CONFDIR cp $DIR/certs/ca.crt $CONFDIR
sudo CONFDIR=$CONFDIR cp $DIR/certs/server.key $CONFDIR
sudo cat ./certs/server.crt ./certs/server-intermediate.crt ./certs/ca.crt > /tmp/server.crt
sudo mv /tmp/server.crt $CONFDIR/server.crt

sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/ca.crt
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/server.key
sudo CONFDIR=$CONFDIR chown nfsnobody:nfsnobody $CONFDIR/server.crt
sudo CONFDIR=$CONFDIR chmod 640 $CONFDIR/ca.crt $CONFDIR/server.key $CONFDIR/server.crt
sudo CONFDIR=$CONFDIR chmod 400 $CONFDIR/server.key

if [ ! -z "$CCP_STORAGE_CLASS" ]; then
	echo "CCP_STORAGE_CLASS is set. Using the existing storage class for the PV."
	expenv -f $DIR/custom-config-ssl-pvc-sc.json | ${CCP_CLI?} create -f -
elif [ ! -z "$CCP_NFS_IP" ]; then
	echo "CCP_NFS_IP is set. Creating NFS based storage volumes."
	expenv -f $DIR/custom-config-ssl-pv-nfs.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/custom-config-ssl-pvc.json | ${CCP_CLI?} create -f -
else
	echo "CCP_NFS_IP and CCP_STORAGE_CLASS not set. Creating HostPath based storage volumes."
	expenv -f $DIR/custom-config-ssl-pv.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/custom-config-ssl-pvc.json | ${CCP_CLI?} create -f -
fi

expenv -f $DIR/custom-config-ssl.json | ${CCP_CLI?} create -f -
