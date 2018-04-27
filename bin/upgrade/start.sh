#!/bin/bash

# Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
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

#
# start the upgrade job
#
# the service looks for the following env vars to be set by
# the cpm-admin that provisioned us
#
# /pgolddata is a volume that gets mapped into this container
# /pgnewdata is a volume that gets mapped into this container
# $OLD_VERSION (e.g. 9.5)
# $NEW_VERSION (e.g. 9.6)
#

source /opt/cpm/bin/common_lib.sh
enable_debugging

function trap_sigterm() {
    echo_warn "Signal trap triggered, beginning shutdown.." >> $PGDATA/trap.output
    echo_warn "Signal trap triggered, beginning shutdown.."
    kill -SIGINT `head -1 $PGDATA/postmaster.pid` >> $PGDATA/trap.output
}

trap 'trap_sigterm' SIGINT SIGTERM

env_check_err "OLD_VERSION"
env_check_err "NEW_VERSION"
env_check_err "OLD_DATABASE_NAME"
env_check_err "NEW_DATABASE_NAME"

export PGDATAOLD=/pgolddata/$OLD_DATABASE_NAME
dir_check_err "PGDATAOLD"

export PGDATANEW=/pgnewdata/$NEW_DATABASE_NAME
dir_check_err "PGDATANEW"

ose_hack

# Set the postgres binary to match the NEW_VERSION

case $NEW_VERSION in
"10")
    echo_info "Setting PGBINNEW to ${NEW_VERSION}."
    export PGBINNEW=/usr/pgsql-10/bin
    export LD_LIBRARY_PATH=/usr/pgsql-10/lib
    ;;
"9.6")
    echo_info "Setting PGBINNEW to ${NEW_VERSION}."
    export PGBINNEW=/usr/pgsql-9.6/bin
    export LD_LIBRARY_PATH=/usr/pgsql-9.6/lib
    ;;
"9.5")
    echo_info "Setting PGBINNEW to ${NEW_VERSION}."
    export PGBINNEW=/usr/pgsql-9.5/bin
    export LD_LIBRARY_PATH=/usr/pgsql-9.5/lib
    ;;
*)
    echo_info "Unsupported NEW_VERSION of ${NEW_VERSION}."
    exit 2
    ;;
esac
case $OLD_VERSION in
"9.6")
    echo_info "Setting PGBINOLD to ${OLD_VERSION}."
    export PGBINOLD=/usr/pgsql-9.6/bin
    ;;
"9.5")
    echo_info "Setting PGBINOLD to ${OLD_VERSION}."
    export PGBINOLD=/usr/pgsql-9.5/bin
    ;;
*)
    echo_info "Unsupported OLD_VERSION of ${OLD_VERSION}."
    exit 2
    ;;
esac

export PATH=/opt/cpm/bin:${PGBINNEW?}:$PATH

env

# Create a clean new data directory
options=" "
if [[ -v PG_LOCALE ]]; then
    options+=" --locale="$PG_LOCALE
fi
if [[ -v XLOGDIR ]]; then
    if [ -d "$XLOGDIR" ]; then
        options+=" --X "$XLOGDIR
    else
        echo_info "XLOGDIR not found. Using default pg_wal directory.."
    fi
fi
if [[ -v CHECKSUMS ]]; then
    options+=" --data-checksums"
fi

echo_info "Using the ${options} flags for initdb.."
${PGBINNEW?}/initdb -D ${PGDATANEW?} $options

# Get the old config files and use those in the new database
cp ${PGDATAOLD?}/postgresql.conf ${PGDATANEW?}
cp ${PGDATAOLD?}/pg_hba.conf ${PGDATANEW?}

# Remove the old postmaster.pid
echo_info "Cleaning up the old postmaster.pid file.."
rm ${PGDATAOLD?}/postmaster.pid

# changing to /tmp is necessary since pg_upgrade has to have write access
cd /tmp

${PGBINNEW?}/pg_upgrade
rc=$?
if (( $rc ==  0 )); then
    echo_info "Upgrade has completed."
else
    echo_err "Problem with upgrade. rc=${rc}"
fi

exit $rc

#while true; do
#	sleep 1000
#done

#wait
