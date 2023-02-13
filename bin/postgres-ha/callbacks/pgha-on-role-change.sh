#!/bin/bash

# Copyright 2019 - 2023 Crunchy Data Solutions, Inc.
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

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"
enable_debugging

source "${CRUNCHY_DIR}/bin/postgres-ha/common/pgha-common.sh"
source "${CRUNCHY_DIR}/bin/postgres-ha/common/pgha-tablespaces.sh"

# set the Patroni port
export $(get_patroni_port)

# set PGHA_PGBACKREST to determine if backrest is enabled
export $(get_pgbackrest_enabled)

# get the node's current role (e.g. "replica") from the second parameter provided by Patroni when
# calling this callback script
action="${1}"
role="${2}"
cluster="${3}"
echo_info "${action} callback called (action=${action} role=${role} cluster=${cluster})"

# get pgbackrest env vars
source "${CRUNCHY_DIR}/bin/postgres-ha/pgbackrest/pgbackrest-set-env.sh"

# if pgBackRest is enabled and the node has been promoted to "primary" (i.e. "master"), and if
# pgBackRest is enabled and is not utilizing a dedicated repository host, then take a new backup
# to ensure the proper creation of replicas.  Also, write a tag to the DCS while the backup is in
# progress to inform other nodes that a backup is in progress.  If a dedicated repository host
# is being utilized (e.g. with the PostgreSQL Operator), then this process will be handled
# externally (e.g. within the PostgreSQL Operator when the repo host is updated following the
# promotion of a replica to primary)
if [[ -f "/tmp/pgha_initialized" && "${role}" ==  "master" && "${PGHA_PGBACKREST}" == "true" ]]
then
    curl -s -XPATCH -d '{"tags":{"primary_on_role_change":"true"}}' "localhost:${PGHA_PATRONI_PORT}/config"
    if [[ ! -v PGBACKREST_REPO1_HOST && ! -v PGBACKREST_REPO_HOST ]]
    then
        pgbackrest backup
        curl -s -XPATCH -d '{"tags":{"primary_on_role_change":null}}' "localhost:${PGHA_PATRONI_PORT}/config"
    fi
fi

if [[ "${role}" == "master" ]]
then
  # For commands that need to directly access the database cluster, ensure the
  # cluster is no longer in recovery
  is_in_recovery=$(psql -At -c "SELECT pg_catalog.pg_is_in_recovery()")
  until [[ "${is_in_recovery}" == "f" ]]
  do
      echo_info "New primary still in recovery, waiting one second..."
      sleep 1
      is_in_recovery=$(psql -At -c "SELECT pg_catalog.pg_is_in_recovery()")
  done

  # if a new tablespace has been added and this is the "primary" node, we need to
  # create the object in the PostgreSQL cluster. This allows us to do so
  tablespaces_create_postgresql_objects "${PGHA_USER}"
fi
