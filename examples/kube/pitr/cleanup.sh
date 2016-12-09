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
# remove any existing components of this example 

kubectl delete pod master-pitr-restore
kubectl delete service master-pitr-restore
sudo rm -rf /nfsfileshare/master-pitr-restore
kubectl delete pvc master-pitr-restore-pvc master-pitr-restore-pgdata-pvc master-pitr-recover-pvc
kubectl delete pv master-pitr-restore-pv master-pitr-restore-pgdata-pv master-pitr-recover-pv

kubectl delete service master-pitr master-pitr-restore
kubectl delete pod master-pitr
kubectl delete job master-pitr-backup-job
kubectl delete pvc master-pitr-pvc backup-master-pitr-pvc master-pitr-recover-pvc master-pitr-restore-pvc master-pitr-wal-pvc
kubectl delete pv master-pitr-pv backup-master-pitr-pv master-pitr-recover-pv master-pitr-restore-pv master-pitr-wal-pv

sudo rm -rf /nfsfileshare/WAL/master-pitr
sudo rm -rf /nfsfileshare/master-pitr
