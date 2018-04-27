#!/bin/bash

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
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

#export OSE_HOST=openshift.default.svc.cluster.local

source /opt/cpm/bin/common_lib.sh
enable_debugging

function create_pgpass() {
    cd /tmp
cat >> ".pgpass" <<-EOF
*:*:*:*:${PG_PRIMARY_PASSWORD}
EOF
    chmod 0600 .pgpass
    export PGPASSFILE=/tmp/.pgpass
}

create_pgpass

export SLEEP_TIME=${SLEEP_TIME:-10}
env_check_info "SLEEP_TIME is set to ${SLEEP_TIME}."

export PG_PRIMARY_SERVICE=$PG_PRIMARY_SERVICE
export GIT_USER_NAME=$GIT_USER_NAME
export GIT_USER_EMAIL=$GIT_USER_EMAIL
export PG_PRIMARY_PORT=$PG_PRIMARY_PORT
export PG_PRIMARY_USER=$PG_PRIMARY_USER
export PG_DATABASE=$PG_DATABASE

export PGROOT=$(find /usr/ -type d -name 'pgsql-*')

echo_info "Setting PGROOT to ${PGROOT?}."

export PATH=$PATH:/opt/cpm/bin:$PGROOT/bin

git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_USER_EMAIL
git config --global push.default simple

pg_dump --schema-only --username=$PG_PRIMARY_USER --dbname=$PG_DATABASE \
    --host=$PG_PRIMARY_SERVICE > /tmp/schema.sql

cd /gitrepo
GIT_PROJECT=`ls | cut -f1 -d' '`
cd $GIT_PROJECT
cp /tmp/schema.sql .
git add schema.sql
git commit -am 'update schema version'
git push
