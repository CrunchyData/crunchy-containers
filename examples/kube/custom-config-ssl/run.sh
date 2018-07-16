#!/bin/bash

# Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
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
CONTAINER_NAME='custom-config-ssl'

${DIR?}/cleanup.sh

${DIR?}/../../ssl-creator.sh "testuser@crunchydata.com" "${CONTAINER_NAME?}" "${DIR}"
if [[ $? -ne 0 ]]
then
    echo_err "Failed to create certs, exiting.."
    exit 1
fi

cp ${DIR?}/certs/server.* ${DIR?}/configs
cp ${DIR?}/certs/ca.* ${DIR?}/configs

create_storage "${CONTAINER_NAME?}"
if [[ $? -ne 0 ]]
then
    echo_err "Failed to create storage, exiting.."
    exit 1
fi

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} secret generic ${CONTAINER_NAME?}-secrets \
    --from-file=ca-crt=${DIR?}/configs/ca.crt \
    --from-file=ca-crl=${DIR?}/configs/ca.crl \
    --from-file=server-crt=${DIR?}/configs/server.crt \
    --from-file=server-key=${DIR?}/configs/server.key \
    --from-file=pgbackrest-conf=${DIR?}/configs/pgbackrest.conf \
    --from-file=pg-hba-conf=${DIR?}/configs/pg_hba.conf \
    --from-file=pg-ident-conf=${DIR?}/configs/pg_ident.conf \
    --from-file=postgresql-conf=${DIR?}/configs/postgresql.conf

expenv -f $DIR/custom-config-ssl.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -

echo ""
echo "To connect via SSL, run the following once the DB is ready: "
echo "psql "postgresql://${CONTAINER_NAME?}:5432/postgres?sslmode=verify-full" -U testuser"
echo ""

echo -e "${YELLOW?}"
echo "Note: The SSL certificates generated are not in the default location, it is required to "
echo "source the env.sh script in this directory prior to running psql:"
echo "source ${CCPROOT?}/examples/kube/custom-config-ssl/env.sh"
echo -e "${RESET?}"
