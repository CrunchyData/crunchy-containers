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

CONF_DIR=/nfsfileshare/bouncerconfig
sudo mkdir $CONF_DIR
sudo cp pgbouncer.ini $CONF_DIR
sudo cp users.txt $CONF_DIR

IPADDRESS=`hostname --ip-address`
cat pgbouncer-pv.json | sed -e "s/IPADDRESS/$IPADDRESS/g" | kubectl create -f -
kubectl create -f pgbouncer-pvc.json
kubectl create -f $BUILDBASE/examples/kube/pgbouncer/pgbouncer-service.json
kubectl create -f $BUILDBASE/examples/kube/pgbouncer/pgbouncer.json
