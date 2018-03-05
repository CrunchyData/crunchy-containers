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

# create the service account used in the containers
$DIR/create-sa.sh

# create the services for the example
oc create -f $DIR/set-service.json
oc create -f $DIR/set-primary-service.json
oc create -f $DIR/set-replica-service.json

# create the PVC
oc create -f $DIR/statefulset-pvc.json

# create the stateful set
#expenv -f $DIR/set.json.dynamic | oc create -f -
expenv -f $DIR/set.json | oc create -f -
