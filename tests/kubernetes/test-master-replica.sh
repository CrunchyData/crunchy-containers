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

set -euo pipefail

source "$BUILDBASE"/tests/kubernetes/pgpass-setup

"$BUILDBASE"/examples/kube/master-replica/run.sh

sleep 45

KUBE_MASTER_SERVICE=$(kubectl get service master-1 --template={{.spec.clusterIP}})
PGPORT=${PGPORT:-5432}
PG_MASTER_USER=${PG_MASTER_USER:-master}
PG_DATABASE=${PG_DATABASE:-userdb}

psql -p $PGPORT -h $KUBE_MASTER_SERVICE -U $PG_MASTER_USER \
 -d $PG_DATABASE \
 -Xqt -c 'CREATE TABLE some_table(some_id serial NOT NULL, some_value integer NOT NULL);'

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test Kubernetes master-replica CREATE TABLE passed"
else
	echo "test Kubernetes master-replica CREATE TABLE FAILED"
	exit $rc
fi

echo "INSERTING DATA"
psql -p $PGPORT -h $KUBE_MASTER_SERVICE -U $PG_MASTER_USER \
 -d $PG_DATABASE \
 -Xqt -c 'INSERT INTO some_table(some_value) VALUES(15), (23), (35);'

KUBE_REPLICA_SERVICE=$(kubectl get service replica-1 --template={{.spec.clusterIP}})

rowcount=$(psql -p $PGPORT -h $KUBE_REPLICA_SERVICE -U $PG_MASTER_USER \
 -d $PG_DATABASE 
 -Xqt -c 'SELECT count(*) from some_table;')

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test Kubernetes master-replica connect to replica passed"
else
	echo "test Kubernetes master-replica connect to replica FAILED"
	exit $rc
fi

if [ $rowcount -eq 3 ]; then 
	echo "test Kubernetes master-replica data replication passed"
else
	echo "test Kubernetes master-replica data replication FAILED"
	exit $rc
fi

exit 0
