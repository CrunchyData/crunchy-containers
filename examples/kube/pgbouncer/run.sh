#!/bin/bash

# Copyright 2016 - 2019 Crunchy Data Solutions, Inc.
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

source ${CCPROOT}/examples/common.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic pgbouncer-secrets \
    --from-literal=pgbouncer-password='password'

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic pgsql-secrets \
    --from-literal=pg-primary-password='password' \
    --from-literal=pg-password='password' \
    --from-literal=pg-root-password='password'

expenv -f $DIR/primary.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
expenv -f $DIR/replica.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
expenv -f $DIR/pgbouncer-primary.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
expenv -f $DIR/pgbouncer-replica.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
