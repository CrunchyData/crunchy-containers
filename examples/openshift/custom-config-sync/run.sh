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

source $CCPROOT/examples/envvars.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

sudo rm -rf $PV_PATH/csprimary

# copy the custom config file to the PVC path
sudo cp $DIR/postgresql.conf $PV_PATH
sudo cp $DIR/pg_hba.conf $PV_PATH
sudo cp $DIR/setup.sql $PV_PATH
sudo chown nfsnobody:nfsnobody $PV_PATH/postgresql.conf $PV_PATH/pg_hba.conf $PV_PATH/setup.sql
sudo chmod g+r $PV_PATH/postgresql.conf $PV_PATH/pg_hba.conf $PV_PATH/setup.sql

oc create -f $DIR/primary-service.json
oc create -f $DIR/replica-service.json
oc process -f $DIR/primary-pod.json -p CCP_IMAGE_PREFIX=$CCP_IMAGE_PREFIX CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
oc process -f $DIR/sync-replica-pod.json -p CCP_IMAGE_PREFIX=$CCP_IMAGE_PREFIX CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
