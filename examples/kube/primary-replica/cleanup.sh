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

kubectl delete pod pr-replica
kubectl delete pod pr-replica-2
sleep  2
kubectl delete service pr-replica
kubectl delete service pr-primary
kubectl delete pod pr-primary
$CCPROOT/examples/waitforterm.sh pr-primary kubectl
$CCPROOT/examples/waitforterm.sh pr-replica kubectl
$CCPROOT/examples/waitforterm.sh pr-replica-2 kubectl
