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

# 
# this example creates the metrics backends with NFS volumes
# for storing their data
#

oc project openshift

LOC=$BUILDBASE/examples/openshift/metrics

IPADDRESS=`hostname --ip-address`
cat $LOC/grafana-pv.json | sed -e "s/IPADDRESS/$IPADDRESS/g" | oc create -f -
cat $LOC/prometheus-pv.json | sed -e "s/IPADDRESS/$IPADDRESS/g" | oc create -f -

oc create -f $LOC/grafana-pvc.json
oc create -f $LOC/prometheus-pvc.json

oc process -f $LOC/prometheus-nfs.json -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
oc process -f $LOC/promgateway.json -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
oc process -f $LOC/grafana-nfs.json -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
