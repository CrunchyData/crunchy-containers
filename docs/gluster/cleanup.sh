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


oc delete endpoints glusterfs-cluster
oc delete pvc gluster-pvc
oc delete pv gluster-pv
oc delete service glusterfs-cluster
oc delete service master-gluster
oc delete pod master-gluster

$CCPROOT/examples/waitforterm.sh master-gluster oc
