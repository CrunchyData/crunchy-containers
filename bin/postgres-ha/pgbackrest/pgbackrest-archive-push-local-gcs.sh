#!/bin/bash

# Copyright 2021 Crunchy Data Solutions, Inc.
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

# This pushes PostgreSQL WAL archives to pgBackRest repositories that are stored
# both on a local filesystem and GCS. We can only consider a WAL log pushed if
# it is pushed to both repositories.
#
# If at most one WAL archive is pushed, we will want to return an error code so
# that PostgreSQL knows to not recycle the WAL archive

# This accepts one argument, the value of "%p" that is used as part of the
# PostgreSQL archiving process. This is referenced as $1

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
# Load the pgBackRest environmental variables
source "${CRUNCHY_DIR}/bin/postgres-ha/pgbackrest/pgbackrest-set-env.sh"

# first try local
pgbackrest archive-push $1
local_exit=$?

# set the repo type flag
archive_push_cmd_args=("--repo1-type=gcs")

# then try GCS
pgbackrest archive-push ${archive_push_cmd_args[*]} $1
gcs_exit=$?

# check each exit code. If one of them fail, exit with their nonzero exit code
if [[ $local_exit -ne 0 ]]
then
    exit $local_exit
fi

if [[ $gcs_exit -ne 0 ]]
then
  exit $gcs_exit
fi
