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

source "$BUILDBASE"/tests/kubernetes/pgpass-setup

"$BUILDBASE"/examples/kube/basic/run.sh

echo "Starting Crunchy Postgres"
sleep 60

KUBE_HOST=$(kubectl get pod basic --template={{.status.podIP}})
PG_MASTER_USER=${PG_MASTER_USER:-master}

psql -h $KUBE_HOST -U $PG_MASTER_USER -Xqt -l

rc=$?

if [ 0 -eq $rc ]; then
	echo "test Kubernetes basic passed"
else
	echo "test Kubernetes master FAILED with $rc"
	exit $rc
fi

exit 0
