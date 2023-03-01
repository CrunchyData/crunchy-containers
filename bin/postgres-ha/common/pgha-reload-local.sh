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

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/postgres-ha/common/common_lib.sh"

bootstrap_file="/tmp/postgres-ha-bootstrap.yaml"
bootstrap_file_bak="${bootstrap_file}.bak"

lock_file="${bootstrap_file}.lock"

# the first parameter passed in is the configMap content for the local server that will
# be merged into the local configuration file
conf_content="${1?}"

# a temporary file used to store the conf that needs to be merged into the current local 
# configuration
merge_file="${bootstrap_file}.merge"

patroni_port="${2?}"

# cleans up any resources and releases the file lock
cleanup() {
    rm -f "${lock_file}" 
}

# reverts any changes to the local config file, then handles the error and exits
# accordingly
handle_error_and_revert() {
    if [[ ${1?} != 0 ]]
    then
        mv "${bootstrap_file_bak}" "${bootstrap_file}" 2>/dev/null
        cleanup
        echo_err "Error reloading local config: ${2?}"
        exit "${1?}"
    fi
}

# if the lock file already exists, then exit
if [[ -f "${lock_file}" ]]
then
    echo_err "Unable to reload configuration, lock already taken"
    exit 1
fi

# grab the lock file
touch "${lock_file}"

# if no diff's detected when comparing the server's configMap content to it's current local
# config, then just exit.  Otherwise proceed with updating and reloading the config.
if echo "${conf_content}" | "${CRUNCHY_DIR}/bin/yq" x --tojson - "${bootstrap_file}" postgresql
then
    cleanup
    exit 0
fi

echo_info "Reload Config: Detected config change, reloading local configuration"

# backup the current patroni config file for the local node
cp "${bootstrap_file}" "${bootstrap_file_bak}"
handle_error_and_revert "$?" "Unable backup configuration"

# now merge the files conf_file
echo "${conf_content}" > "${merge_file}"
"${CRUNCHY_DIR}/bin/yq" d -i "${bootstrap_file}" postgresql && \
    "${CRUNCHY_DIR}/bin/yq" m -i "${bootstrap_file}" "${merge_file}"
handle_error_and_revert "$?" "Unable to merge files"

# Now issue a patroni reload
curl -s -XPOST "http://localhost:${patroni_port}/reload"
handle_error_and_revert "$?" "Unable to reload local configuration"

echo_info "Reload Config: Successfully scheduled config reload"

cleanup
