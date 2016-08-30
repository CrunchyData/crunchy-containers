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

source $BUILDBASE/examples/envvars.sh

LOC=$BUILDBASE/examples/openshift/tutorial

echo "create services for master and replicas..."
oc create -f $LOC/master-service.json
oc create -f $LOC/replica-service.json

echo "create prometheus pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/prometheus.json | oc create -f -
echo "create promgateway pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/promgateway.json | oc create -f -
echo "create grafana pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/grafana.json | oc create -f -

echo "setting up NFS data directory for pgadmin4..."
DATADIR=/nfsvolumes

array=( 01 02 03 04 05 06 07 08 09 10 )
for i in "${array[@]}"
do
	mkdir -p $DATADIR/pv$i/pgadmin4 
	cp ./config_local.py $DATADIR/pv$i/pgadmin4
	cp ./pgadmin4.db $DATADIR/pv$i/pgadmin4
	chmod -R 777 $DATADIR/pv$i
done

echo "create pgadmin4 pod.."

# for the tutorial, we have a VM that already has the PVs created so
# we comment out this next line for that environment
#envsubst < pgadmin4-nfs-pv.json |  oc create -f -
oc create -f pgadmin4-nfs-pvc.json

oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/pgadmin4.json | oc create -f -
echo "create master pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/master-pod.json | oc create -f -
echo "sleeping 20 secs before creating slaves..."
sleep 20
echo "create slave pod.."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/replica-dc.json | oc create -f -
echo "create pgpool dc..."
oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/pgpool-dc.json | oc create -f -
