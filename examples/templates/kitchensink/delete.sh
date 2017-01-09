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

oc delete service kitchensink-master
oc delete service kitchensink-slave
oc delete pod kitchensink-watch
oc delete pod kitchensink-master
oc delete pod kitchensink-sync-slave
oc delete dc kitchensink-pgpool-rc
oc delete dc kitchensink-slave-dc
oc delete service kitchensink-pgpool-rc

$BUILDBASE/examples/waitforterm.sh kitchensink-master oc
$BUILDBASE/examples/waitforterm.sh kitchensink-slave oc
