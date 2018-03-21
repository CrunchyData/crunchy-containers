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

kubectl create -f $DIR/primary-service.json
kubectl create -f $DIR/replica-service.json

kubectl create -f $DIR/pguser-secret.json
kubectl create -f $DIR/pgprimary-secret.json
kubectl create -f $DIR/pgroot-secret.json

kubectl create -f $DIR/primary-dc-pvc.json
kubectl create -f $DIR/primary-dc-pgbackrest-pvc.json
kubectl create -f $DIR/primary-dc-pgwal-pvc.json

kubectl create configmap postgresql-conf --from-file=postgresql.conf --from-file=pghba=pg_hba.conf --from-file=setup.sql

expenv -f $DIR/primary-dc.json | kubectl create -f -
expenv -f $DIR/replica-dc.json | kubectl create -f -
expenv -f $DIR/replica2-dc.json | kubectl create -f -
