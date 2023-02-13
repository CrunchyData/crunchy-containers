#!/bin/bash

# Copyright 2020 - 2023 Crunchy Data Solutions, Inc.
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

# These functions determine if any tablespaces should be created. this involves
# ensuring that the directory is created on the disk

# *****************************************************************************
# The list of tablespaces is available in the PGHA_TABLESPACES variable in the
# format:
#
# "tablespace1,tablespace2"
#
# This needs to be parsed out
# *****************************************************************************

# tablespaces_path returns the path used for a tablespace
# accept an argument of a tablespace name
function tablespaces_path() {
  tablespace=$1

  echo "/tablespaces/${tablespace}/${tablespace}"
}

# tablespaces_create_directory creates any directories on the mount for  all
# of the tablespaces that are available, if the directory  has not already been
# created
function tablespaces_create_directory() {
  IFS=',' read -r -a TABLESPACES <<< "${PGHA_TABLESPACES}"

  # iterate through the list of tablespaces if any are found
  for TABLESPACE in "${TABLESPACES[@]}"
  do
    TABLESPACE_PATH=$(tablespaces_path "${TABLESPACE}")

    # only create the tablespace if the directory does not exist
    if [[ ! -d "${TABLESPACE_PATH}" ]]
    then
      echo_info "create directory for tablespace \"${TABLESPACE}\" on mount point \"${TABLESPACE_PATH}\""

      # create the folder that the tablespace will be mounted to as well as set its
      # permissions correctly. This has to go "two deep" in order to account for
      # the direcory structure of the mounted file system
      mkdir -p "${TABLESPACE_PATH}"
      chmod 0700 "${TABLESPACE_PATH}"
    fi
  done
}

# tablespaces_create_postgresql_objects updates PostgreSQL to set up all of the
# tablespace objects within the database, if the object does not exist
#
# takes one argument: PGHA_USER or a user to create a grant on the tablespace
# for
function tablespaces_create_postgresql_objects() {
  user=$1
  IFS=',' read -r -a TABLESPACES <<< "${PGHA_TABLESPACES}"

  # iterate through the list of tablespaces if any are found and try to create
  for TABLESPACE in "${TABLESPACES[@]}"
  do
    sql="SELECT EXISTS(SELECT 1 FROM pg_catalog.pg_tablespace WHERE spcname = '${TABLESPACE}')"
    tablespace_exists=$(psql -At -c "${sql}")

    # only try to create the tablespace if it does not already exist
    if [[ "${tablespace_exists}" == "f" ]]
    then
      TABLESPACE_PATH=$(tablespaces_path "${TABLESPACE}")

      echo_info "Adding \"${TABLESPACE}\" at location \"${TABLESPACE_PATH}\" to PostgreSQL"

      # first, create the tablespace
      sql="CREATE TABLESPACE \"${TABLESPACE}\" LOCATION '${TABLESPACE_PATH}';"
      psql -c "${sql}"

      # then, ensure the default user is able to create objects on the
      # tablespace
      sql="GRANT CREATE ON TABLESPACE \"${TABLESPACE}\" TO \"${user}\";"
      psql -c "${sql}"
    fi
  done
}
