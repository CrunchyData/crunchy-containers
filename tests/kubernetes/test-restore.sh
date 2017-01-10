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

if [ -z $BACKUP_PATH ]; then
	echo "Must provide \$BACKUP_PATH in order to restore."
	exit 1
fi

source "$BUILDBASE"/examples/envvars.sh

source "$BUILDBASE"/tests/kubernetes/pgpass-setup

"$BUILDBASE"/examples/kube/master-restore/run.sh

sleep 30
KUBE_SERVICE=$(kubectl get service restored-master --template={{.spec.clusterIP}})

psql -h $KUBE_SERVICE -U masteruser userdb -Xqt -l

rc=$?

if [ 0 -eq $rc ]; then
	echo "test kubernetes restore passed"
else
	echo "test kubernetes restore FAILED with $rc"
	exit $rc
fi

exit 0
