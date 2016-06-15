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

oc project openshift

NFS=/nfsfileshare/custom-config
sudo mkdir $NFS
sudo cp `pwd`/setup.sql $NFS

IPADDRESS=`hostname --ip-address`
cat custom-config-pv.json | sed -e "s/IPADDRESS/$IPADDRESS/g" | oc create -f -
oc create -f custom-config-pvc.json
oc process -f custom-config.json | oc create -f -
