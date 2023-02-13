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

# while the cluster is initializing, readiness is determined based on whether or not the
# 'pgha_initialized' file exists.  Once the cluster has been initialized and this file has been
# created, the Patroni "health" endpoint will then be utilized for any future readiness checks.
if [[ -f "/tmp/pgha_initialized" ]]
then

    # set the Patroni port
    export $(get_patroni_port)

    # obtain HTTP status code returned from the "health" endpoint
    status_code=$(curl -o /dev/stderr -w "%{http_code}" "127.0.0.1:${PGHA_PATRONI_PORT}/health" 2> /dev/null)

    # the local node is considered heathly if the HTTP status code returned from the local "health"
    # endpoint is greated than 200 or less than 400, in accordance with the Kubernetes documenation
    # for HTTP readiness checks, i.e. per the docs "any code greater than or equal to 200 and less
    # than 400 indicates success. Any other code indicates failure."
    if [[ $status_code -ge 200 && $status_code -lt 400 ]]
    then
        exit 0
    fi
fi

# return exit code 1 if not initialized or health endpoint check fails
exit 1
