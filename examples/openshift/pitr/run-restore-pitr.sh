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

oc delete pod primary-pitr-restore
oc delete service primary-pitr-restore
oc delete pvc restore-pvc primary-pitr-restore-pvc
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/primary-pitr-restore

# create the recover pv and pvc
expenv -f $DIR/recover-pv.json | oc create -f -
oc create -f $DIR/recover-pvc.json
oc create -f $DIR/primary-pitr-restore-pvc.json

oc create -f $DIR/restore-service.json

# start up the database container
expenv -f $DIR/primary-pitr-restore.json | oc create -f -
