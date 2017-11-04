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

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# create some sample pv to use
envsubst < $DIR/pv1.json | kubectl create -f -
envsubst < $DIR/pv2.json | kubectl create -f -
envsubst < $DIR/pv3.json | kubectl create -f -

# create the pvc we will use for all pods in the set
kubectl create -f $DIR/pvc.json
