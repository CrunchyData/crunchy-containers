#!/bin/bash
# Copyright 2017 Crunchy Data Solutions, Inc.
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

oc create -f $DIR/dba-sa.json

oc policy add-role-to-group edit system:serviceaccounts -n $NAMESPACE
oc policy add-role-to-user view system:serviceaccount:$NAMESPACE:dba-sa

#
# this next commands lets the dba-sa service account have
# the permissions of 'cluster-admin' which allows it
# to create PVCs required by the backup job
# capability of the dba container
#
oadm policy add-cluster-role-to-user cluster-admin system:serviceaccount:$NAMESPACE:dba-sa

oc process \
	-p CCP_IMAGE_PREFIX=$CCP_IMAGE_PREFIX \
	-p CCP_IMAGE_TAG=$CCP_IMAGE_TAG \
	-p NAMESPACE=$NAMESPACE \
	-f $DIR/primary-dba-backup.json | oc create -f -
