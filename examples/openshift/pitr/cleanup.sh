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

oc delete service master-pitr master-pitr-restore
oc delete pod master-pitr master-pitr-restore
oc delete job backup-master-pitr-nfs
oc delete pvc master-pitr-pvc backup-master-pitr-pvc master-pitr-recover-pvc master-pitr-restore-pvc master-pitr-wal-pvc


sudo rm -rf /nfsfileshare/WAL/master-pitr
sudo rm -rf /nfsfileshare/master-pitr
