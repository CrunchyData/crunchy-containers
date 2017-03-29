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

source $CCPROOT/examples/envvars.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

oc delete dc m-s-rc-pvc-replica
oc delete pod m-s-rc-pvc-master 
oc delete pod m-s-rc-pvc-replica
oc delete pod -l name=m-s-rc-pvc-master
$CCPROOT/examples/waitforterm.sh m-s-rc-pvc-master oc
$CCPROOT/examples/waitforterm.sh m-s-rc-pvc-replica oc
oc delete service m-s-rc-pvc-master
oc delete service m-s-rc-pvc-replica

sudo rm -rf $NFS_PATH/m-s-rc-pvc*
