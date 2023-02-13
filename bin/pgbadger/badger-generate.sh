#!/bin/bash

# Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
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
export BADGER_CUSTOM_OPTS=${BADGER_CUSTOM_OPTS:-}

TARGET=${HOSTNAME?}
if [[ -v BADGER_TARGET ]]
then
    echo_info "BADGER_TARGET environment variable set.  Setting PGDATA target.."
    TARGET=${BADGER_TARGET?}
fi

# The following command build-up is to avoid a bug where
# BADGER_CUSTOM_OPTS might have quotes in the value.  Bash does
# automatic escaping of quotes when found in a value which
# breaks pgBadger.
if [[ -f /tmp/cmd ]]
then
    rm -f /tmp/cmd
fi

echo -n "/bin/pgbadger -f stderr " >> /tmp/cmd
echo -n "${BADGER_CUSTOM_OPTS?} " >> /tmp/cmd
echo -n "-o /report/index.html /pgdata/${TARGET?}/pg_log/*.log"  >> /tmp/cmd

echo_info "Creating pgBadger output.."
source /tmp/cmd
