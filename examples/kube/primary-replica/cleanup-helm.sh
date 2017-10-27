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

kubectl delete pod crunchy-replica
sleep  2
kubectl delete service crunchy-replica
kubectl delete service crunchy-primary
kubectl delete pod crunchy-primary
$CCPROOT/examples/waitforterm.sh crunchy-primary kubectl
$CCPROOT/examples/waitforterm.sh crunchy-replica kubectl
