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

"$BUILDBASE"/examples/kube/master-nfs/run.sh

sleep 60

KUBE_HOST=$(kubectl get pod master-nfs --template={{.status.podIP}})
PGPORT=${PGPORT:-5432}
PG_MASTER_USER=${PG_MASTER_USER:-master}
PG_DATABASE=${PG_DATABASE:-userdb}

psql -p $PGPORT -h $KUBE_HOST -U $PG_MASTER_USER -d $PG_DATABASE -c 'SELECT now();'

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test Kubernetes master-nfs passed"
else
	echo "test Kubernetes master-nfs FAILED"
	exit $rc
fi

exit 0
