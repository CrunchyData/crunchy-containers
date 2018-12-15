#!/bin/bash

# Copyright 2017 - 2019 Crunchy Data Solutions, Inc.
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

set -e

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

env_check_err "STANZA"

BACKREST_CONF='/pgconf/pgbackrest.conf'
if [[ ! -f ${BACKREST_CONF?} ]]
then
    echo_err "${BACKREST_CONF?} does not exist.  A pgBackRest configuration file must be mounted to /pgconf.  Exiting.."
    exit 1
fi

if [[ -v PG_HOSTNAME ]]
then
    if [[ ! -d /pgdata/${PG_HOSTNAME?} ]]
    then
        mkdir -p /pgdata/${PG_HOSTNAME?}
    fi
fi

echo_info "Starting restore.."
if [[ -v PITR_TARGET ]]
then
    echo_info "Point In Time Recovery restore detected.  Enabling PITR restore.."
    pgbackrest \
        --config=${BACKREST_CONF?} \
        --stanza=${STANZA?} \
        --delta --type=time "--target=${PITR_TARGET?}" restore
else
    if [[ -v DELTA ]]
    then
        echo_info "Delta restore detected.  Enabling delta restore.."
        restore_type='--delta'
    else
        echo_info "Full restore detected.  Enabling full restore.."
    fi

    pgbackrest \
        --config=${BACKREST_CONF?} \
        --stanza=${STANZA?} \
        ${restore_type:-} ${BACKREST_CUSTOM_OPTS:-} restore
fi

echo_info "Restore completed.  Exiting.."
exit 0