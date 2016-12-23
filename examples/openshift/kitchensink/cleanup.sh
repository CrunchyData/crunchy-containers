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

oc delete pv ks-master-pv
oc delete pv ks-sync-replica-pv
oc delete pvc ks-master-pvc
oc delete pvc ks-sync-replica-pvc
oc delete service ks-master
oc delete service ks-replica
oc delete pod ks-watch
oc delete pod ks-master
oc delete pod ks-sync-replica
oc delete dc ks-pgpool-rc
oc delete dc ks-replica-dc
oc delete service ks-pgpool-rc

$BUILDBASE/examples/waitforterm.sh ks-master oc
$BUILDBASE/examples/waitforterm.sh ks-replica oc
