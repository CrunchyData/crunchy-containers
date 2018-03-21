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
CONTAINER='custom-config'

kubectl delete service custom-config
kubectl delete pod custom-config
kubectl delete pvc custom-config-pvc

sudo rm $CCP_STORAGE_PATH/setup.sql
sudo rm $CCP_STORAGE_PATH/pg_hba.conf
sudo rm $CCP_STORAGE_PATH/postgresql.conf
sudo rm -rf $CCP_STORAGE_PATH/$CONTAINER

$CCPROOT/examples/waitforterm.sh custom-config kubectl
