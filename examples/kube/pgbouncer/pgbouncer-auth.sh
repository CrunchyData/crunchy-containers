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

echo "Setting up pgBouncer.."

echo "Obtaining pg-primary service address"
export SERVICE_IP=`${CCP_CLI} get -o jsonpath="{.spec.clusterIP}" service pg-primary`

# set password to allow psql to pick it up non-interactively
export PGPASSWORD=password 

echo -e "Running setup SQL on ${SERVICE_IP} \n"

for DB in $(psql -h $SERVICE_IP -U postgres -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1')")
do

    echo $DB
    psql -h $SERVICE_IP -U postgres -d $DB --single-transaction \
	 -v ON_ERROR_STOP=1 < ./pgbouncer.sql  2> ./pgbouncer-auth.stderr
    echo -e "\n"
done

