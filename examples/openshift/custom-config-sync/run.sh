#!/bin/bash
# Copyright 2018 Crunchy Data Solutions, Inc.
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

sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/csprimary

# copy the custom config file to the PVC path
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH cp $DIR/postgresql.conf $CCP_STORAGE_PATH
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH cp $DIR/pg_hba.conf $CCP_STORAGE_PATH
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH cp $DIR/setup.sql $CCP_STORAGE_PATH
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH chown nfsnobody:nfsnobody $CCP_STORAGE_PATH/postgresql.conf $CCP_STORAGE_PATH/pg_hba.conf $CCP_STORAGE_PATH/setup.sql
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH chmod g+r $CCP_STORAGE_PATH/postgresql.conf $CCP_STORAGE_PATH/pg_hba.conf $CCP_STORAGE_PATH/setup.sql

oc create -f $DIR/custom-config-sync-pvc.json
oc create -f $DIR/custom-config-sync-pgconf-pvc.json

oc create -f $DIR/primary-service.json
oc create -f $DIR/replica-service.json
expenv -f $DIR/primary-pod.json  | oc create -f -
expenv -f $DIR/sync-replica-pod.json  | oc create -f -
