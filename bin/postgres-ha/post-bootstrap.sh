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

export PGHOST="/tmp"

source /opt/cpm/bin/common_lib.sh
enable_debugging

echo_info "postgres-ha post-bootstrap starting"

# Run either a custom or the defaul setup.sql file
if [[ -f "/pgconf/setup.sql" ]]
then
    echo_info "Using custom setup.sql"
    cp "/pgconf/setup.sql" "/tmp"
else
    echo_info "Using default setup.sql"
    cp "/opt/cpm/bin/setup.sql" "/tmp"
fi

# Always replace PGHA_USER_PASSWORD before PGHA_USER
sed -i "s/PGHA_USER_PASSWORD/$PGHA_USER_PASSWORD/g" "/tmp/setup.sql"
sed -i "s/PGHA_USER/$PGHA_USER/g" "/tmp/setup.sql"
sed -i "s/PGHA_DATABASE/$PGHA_DATABASE/g" "/tmp/setup.sql"

echo_info "Running setup.sql file"
psql < "/tmp/setup.sql"

# If there are any tablespaces, create them as a convenience to the user
IFS=',' read -r -a TABLESPACES <<< "${PGHA_TABLESPACES}"
# Iterate through the list and both create the tablespace in the PostgreSQL
# instance, and ensure the PGHA_USER is able to utilize them
for TABLESPACE in "${TABLESPACES[@]}"
do
  TABLESPACE_PATH="/tablespaces/${TABLESPACE}/${TABLESPACE}"
  echo_info "Adding \"${TABLESPACE}\" at location \"${TABLESPACE_PATH}\" to PostgreSQL"

  TABLESESPACE_SQL="CREATE TABLESPACE \"${TABLESPACE}\" LOCATION '${TABLESPACE_PATH}';"
  psql -c "${TABLESESPACE_SQL}"

  TABLESPACE_GRANT_SQL="GRANT CREATE ON TABLESPACE \"${TABLESPACE}\" TO \"${PGHA_USER}\";"
  psql -c "${TABLESPACE_GRANT_SQL}"
done

# Run audit.sql file if exists
if [[ -f "/pgconf/audit.sql" ]]
then
    echo_info "Running custom audit.sql file"
    psql < "/pgconf/audit.sql"
fi

# Apply enhancement modules
echo_info "Applying enahncement modules"
for module in /opt/cpm/bin/modules/*.sh
do
    echo_info "Applying module ${module}"
    source "${module}"
done

echo_info "postgres-ha post-bootstrap complete"
