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

set -u

if [ -z ${BACKUP_PATH+1} ]; then
	echo "Must set \$BACKUP_PATH in order to restore. E.g. \`export \$BACKUP_PATH=basic/2017-01-01-11-28-11\`"
	exit 1
fi

source "$BUILDBASE"/examples/envvars.sh

source "$BUILDBASE"/tests/kubernetes/pgpass-setup

echo "Starting restore"
"$BUILDBASE"/examples/kube/master-restore/run.sh

sleep 30
KUBE_SERVICE=$(kubectl get service restored-master --template={{.spec.clusterIP}})
PG_MASTER_USER=${PG_MASTER_USER:-master}

psql -h $KUBE_SERVICE -U $PG_MASTER_USER -Xqt -l

rc=$?

if [ 0 -eq $rc ]; then
	echo "test kubernetes restore from backup passed"
else
	echo "test kubernetes restore from $BACKUP_PATH FAILED with $rc"
	exit $rc
fi

exit 0
