#!/bin/bash
# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
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

${CCP_CLI?} delete pod restore-pitr
${CCP_CLI?} delete service restore-pitr
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/restore-pitr

${CCP_CLI?} delete service pitr
${CCP_CLI?} delete pod pitr
${CCP_CLI?} delete job backup-pitr

${CCP_CLI?} delete pvc pitr-pgdata pitr-pgwal backup-pitr-pgdata backup-pitr-pgdata restore-pitr-pgdata recover-pv recover-pvc

sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/WAL/pitr
sudo CCP_STORAGE_PATH=$CCP_STORAGE_PATH rm -rf $CCP_STORAGE_PATH/pitr
