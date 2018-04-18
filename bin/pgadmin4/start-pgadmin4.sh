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

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

export PATH=$PATH:/usr/pgsql-*/bin
PGADMIN_DIR='/usr/lib/python2.7/site-packages/pgadmin4-web'
APACHE_PIDFILE='/tmp/httpd.pid'

function trap_sigterm() {
    echo_info "Doing trap logic.."
    echo_warn "Clean shutdown of Apache.."
    /usr/sbin/httpd -k stop
    kill -SIGINT $(head -1 $APACHE_PIDFILE)
}

trap 'trap_sigterm' SIGINT SIGTERM

env_check_err "PGADMIN_SETUP_EMAIL"
env_check_err "PGADMIN_SETUP_PASSWORD"

if [[ ${ENABLE_TLS:-false} == 'true' ]]
then
    echo_info "TLS enabled. Applying https configuration.."
    if [[ ( ! -f /certs/server.key ) || ( ! -f /certs/server.crt ) ]]; then
        echo_err "ENABLE_TLS true but /certs/server.key or /certs/server.crt not found, aborting"
        exit 1
    fi
    cp /opt/cpm/conf/pgadmin-https.conf /var/lib/pgadmin/pgadmin.conf
else
    echo_info "TLS disabled. Applying http configuration.."
    cp /opt/cpm/conf/pgadmin-http.conf /var/lib/pgadmin/pgadmin.conf
fi

cp /opt/cpm/conf/config_local.py /var/lib/pgadmin/config_local.py

sed -i "s|SERVER_PORT|${SERVER_PORT:-5050}|g" /var/lib/pgadmin/pgadmin.conf
sed -i "s/^DEFAULT_SERVER_PORT.*/DEFAULT_SERVER_PORT = ${SERVER_PORT:-5050}/" /var/lib/pgadmin/config_local.py
sed -i "s|\"pg\":.*|\"pg\": \"/usr/pgsql-${PGVERSION?}/bin\",|g" /var/lib/pgadmin/config_local.py

cd ${PGADMIN_DIR?}

if [[ ! -f /var/lib/pgadmin/pgadmin4.db ]]
then
    echo_info "Setting up pgAdmin4 database.."
    python setup.py
fi

cd ${PGADMIN_DIR?}

echo_info "Starting Apache web server.."
/usr/sbin/httpd -D FOREGROUND &
echo $! > $APACHE_PIDFILE

wait
