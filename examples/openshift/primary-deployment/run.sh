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

oc create -f $DIR/primary-dc-pvc.json
oc create -f $DIR/primary-dc-pgbackrest-pvc.json
oc create -f $DIR/primary-dc-pgwal-pvc.json

oc create -f $DIR/replica-dc-pvc.json
oc create -f $DIR/replica-dc-pgbackrest-pvc.json
oc create -f $DIR/replica-dc-pgwal-pvc.json

oc create -f $DIR/replica2-dc-pvc.json
oc create -f $DIR/replica2-dc-pgbackrest-pvc.json
oc create -f $DIR/replica2-dc-pgwal-pvc.json

oc create -f $DIR/pguser-secret.json
oc create -f $DIR/pgprimary-secret.json
oc create -f $DIR/pgroot-secret.json

oc create configmap postgresql-conf --from-file=postgresql.conf --from-file=pghba=pg_hba.conf --from-file=setup.sql


oc create -f $DIR/primary-service.json
oc create -f $DIR/replica-service.json

expenv -f $DIR/primary-dc.json  | oc create -f -
echo "waiting 20 seconds for primary to become active..."
sleep 20
expenv -f $DIR/replica-dc.json  | oc create -f -
expenv -f $DIR/replica2-dc.json  | oc create -f -
