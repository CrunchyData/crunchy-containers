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

kubectl delete service master-1
kubectl delete service replica-1
kubectl delete pod master-1
kubectl delete pod replica-1a
kubectl delete pod replica-1b
"$BUILDBASE"/examples/waitforterm.sh master-1 kubectl
"$BUILDBASE"/examples/waitforterm.sh replica-1a kubectl
"$BUILDBASE"/examples/waitforterm.sh replica-1b kubectl
