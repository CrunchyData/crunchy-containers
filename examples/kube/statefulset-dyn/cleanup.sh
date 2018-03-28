#!/bin/bash
# Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
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

${CCP_CLI?} delete statefulset statefulset-dyn
${CCP_CLI?} delete sa statefulset-dyn-sa
${CCP_CLI?} delete clusterrolebinding statefulset-dyn-sa
${CCP_CLI?} delete service statefulset-dyn statefulset-dyn-primary statefulset-dyn-replica
${CCP_CLI?} delete pvc pgdata-statefulset-dyn-0 pgdata-statefulset-dyn-1
${CCP_CLI?} delete pod statefulset-dyn-0 statefulset-dyn-1
${CCP_CLI?} delete storageclass slow
