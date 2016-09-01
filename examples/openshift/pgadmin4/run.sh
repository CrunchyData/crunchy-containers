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

source $BUILDBASE/examples/envvars.sh

LOC=$BUILDBASE/examples/openshift/pgadmin4

# uncomment the next line if you need to create an NFS PV for
# your environment
#envsubst < pgadmin4-nfs-pv.json |  oc create -f -

oc create -f pgadmin4-nfs-pvc.json

oc process -v CCP_IMAGE_TAG=$CCP_IMAGE_TAG -f $LOC/pgadmin4.json | oc create -f -
