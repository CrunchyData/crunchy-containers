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

oc project jeff-project

CONFIGDIR=/nfsfileshare/bouncerconfig

sudo rm -rf $CONFIGDIR
sudo mkdir $CONFIGDIR
sudo chmod 777 $CONFIGDIR

LOC=$HOME/dedicated-examples/pgbouncer

cp $LOC/pgbouncer.ini $CONFIGDIR
cp $LOC/users.txt $CONFIGDIR

IPADDRESS=`hostname --ip-address`
cat $LOC/pgbouncer-pv.json | sed -e "s/IPADDRESS/$IPADDRESS/g" | oc create -f -
oc create -f $LOC/pgbouncer-pvc.json
oc process -f $LOC/pgbouncer.json | oc create -f -
