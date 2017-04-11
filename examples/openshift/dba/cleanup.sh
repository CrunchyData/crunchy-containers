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

oc delete job master-dba-vac
oc delete job master-dba-backup
oc delete sa dba-sa
oc delete pod master-dba
oc delete service master-dba
oc delete pvc master-dba-backup-pvc

../../waitforterm.sh master-dba oc
