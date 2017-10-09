#!/bin/bash

# Copyright 2017 Crunchy Data Solutions, Inc.
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

set -x
set -e
function verify {
  : ${CCPROOT?"ERROR: Need to set CCPROOT To the root directory for this repository."}
}
source $CCPROOT/examples/envvars.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Executing with root dir = $DIR, and crunchy containers root = $CCPROOT."

${DIR}/cleanup.sh
kubectl create -f $DIR/master-service.json
kubectl create -f $DIR/replica-service.json

kubectl create -f $DIR/pguser-secret.json
kubectl create -f $DIR/pgmaster-secret.json
kubectl create -f $DIR/pgroot-secret.json

kubectl create configmap postgresql-conf --from-file=postgresql.conf --from-file=pghba=pg_hba.conf --from-file=setup.sql

python envsubst.py < $DIR/master-dc.json | kubectl create -f -
python envsubst.py < $DIR/replica-dc.json | kubectl create -f -
python envsubst.py < $DIR/replica2-dc.json | kubectl create -f -
