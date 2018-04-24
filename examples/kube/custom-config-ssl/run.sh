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


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

set -e
$DIR/ssl-creator.sh testuser custom-config-ssl
set +e

${CCP_CLI?} create secret generic postgres-ssl-secrets\
    --from-file=ca-crt=${DIR?}/certs/ca.crt \
    --from-file=ca-crl=${DIR?}/certs/ca.crl \
    --from-file=server-crt=${DIR?}/certs/server.crt \
    --from-file=server-key=${DIR?}/certs/server.key \
    --from-file=pgbackrest-conf=${DIR?}/configs/pgbackrest.conf \
    --from-file=pg-hba-conf=${DIR?}/configs/pg_hba.conf \
    --from-file=postgresql-conf=${DIR?}/configs/postgresql.conf

expenv -f $DIR/custom-config-ssl-pv.json | ${CCP_CLI?} create -f -
expenv -f $DIR/custom-config-ssl.json | ${CCP_CLI?} create -f -

echo ""
echo "To connect via SSL, run the following once the DB is ready: "
echo "source ./env.sh"
echo "psql "postgresql://custom-config-ssl:5432/postgres?sslmode=verify-full" -U testuser"
echo ""

exit 0
