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
# remove any existing components of this example 

kubectl delete pod primary-pitr-restore
kubectl delete service primary-pitr-restore
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/primary-pitr-restore

kubectl delete service primary-pitr primary-pitr-restore
kubectl delete pod primary-pitr
kubectl delete job primary-pitr-backup-job

kubectl delete pvc primary-pitr-pvc primary-pitr-pgwal-pvc primary-pitr-backup-pvc backup-primary-pitr-pvc primary-pitr-restore-pvc recover-pvc 

sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/WAL/primary-pitr
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/primary-pitr
