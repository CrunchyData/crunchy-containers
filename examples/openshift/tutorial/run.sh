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

export CCP_IMAGE_TAG=centos7-9.5-1.2.2

echo "create services for master and replicas..."
oc create -f ./master-service.json
oc create -f ./replica-service.json

echo "create prometheus pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f ./prometheus.json | oc create -f -
echo "create promgateway pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f ./promgateway.json | oc create -f -
echo "create grafana pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f ./grafana.json | oc create -f -

echo "create pgadmin4 pod.."

# for the tutorial, we will not have pgadmin4 uses NFS volumes
# to make it easier for the students...normally you would want
# to persist the pgadmin database and config files...see the pgadmin4
# example if you ever want to do this
#envsubst < pgadmin4-nfs-pv.json |  oc create -f -
#oc create -f pgadmin4-nfs-pvc.json

oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f ./pgadmin4.json | oc create -f -
echo "create master pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f ./master-pod.json | oc create -f -
echo "sleeping 20 secs before creating slaves..."
sleep 20
echo "create slave pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f ./replica-dc.json | oc create -f -
echo "create pgpool dc..."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f ./pgpool-dc.json | oc create -f -

# expose routes for the web interfaces
oc expose service prometheus
oc expose service promgateway
oc expose service grafana
oc expose service pgadmin4

oc create -f ./pgbadger-route.json

# create the watch pod
oc create -f ./watch-sa.json
oc policy add-role-to-group edit system:serviceaccounts -n openshift
oc policy add-role-to-group edit system:serviceaccounts -n default
oc process -f ./watch.json -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -


