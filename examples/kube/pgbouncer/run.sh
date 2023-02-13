#!/bin/bash

# Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
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


create_storage "pgbouncer"
if [[ $? -ne 0 ]]
then
    echo_err "Failed to create storage, exiting.."
    exit 1
fi


${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic pgbouncer-secrets \
    --from-literal=pgbouncer-password='password'

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} secret \
    pgbouncer-secrets cleanup=${CCP_NAMESPACE?}-pgbouncer

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic pgsql-secrets \
    --from-literal=pg-primary-password='password' \
    --from-literal=pg-password='password' \
    --from-literal=pg-root-password='password'

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap pgbouncer-config-pgconf \
    --from-file ${DIR?}/post-configs/pgbouncer-auth.sql \
    --from-file ${DIR?}/post-configs/post-start-hook.sh

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap \
    pgbouncer-config-pgconf cleanup=${CCP_NAMESPACE?}-pgbouncer

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} secret \
    pgsql-secrets cleanup=${CCP_NAMESPACE?}-pgbouncer

cat $DIR/primary.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
cat $DIR/replica.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
cat $DIR/pgbouncer-primary.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
cat $DIR/pgbouncer-replica.json | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
