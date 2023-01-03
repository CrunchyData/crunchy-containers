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


# Start script for the compacted pgBackRest image
# Used to run correct start script based on the MODE
# environment variable

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"
enable_debugging

env_check_err "MODE"

echo_info "Image mode found: ${MODE}"

case $MODE in
    pgbackrest)
      echo_info "Starting in 'pgbackrest' mode"
      exec "${CRUNCHY_DIR}/bin/pgbackrest"
      ;;
    pgbackrest-repo)
      echo_info "Starting in 'pgbackrest-repo' mode"
      exec "/usr/local/bin/pgbackrest-repo.sh"
      ;;
    pgbackrest-restore)
      echo_info "Starting in 'pgbackrest-restore' mode"
      exec "${CRUNCHY_DIR}/bin/pgbackrest-restore.sh"
      ;;
    *)
      echo_err "Invalid Image Mode; Please set the MODE environment variable to a supported mode"
      exit 1
      ;;
esac
