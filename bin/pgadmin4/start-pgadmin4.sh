#!/bin/bash

# Copyright 2015 Crunchy Data Solutions, Inc.
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

if [[ ( ! -v PGADMIN_SETUP_EMAIL ) || ( ! -v PGADMIN_SETUP_PASSWORD ) ]]; then
    echo "PGADMIN_SETUP_EMAIL or PGADMIN_SETUP_PASSWORD environment variable is not set, aborting"
    exit 1
fi

if [[ ${ENABLE_TLS:-false} == 'true' ]]
then
    echo "TLS enabled.."
    if [[ ( ! -f /certs/server.key ) || ( ! -f /certs/server.crt ) ]]; then
	echo "ENABLE_TLS true but /certs/server.key or /certs/server.crt not found, aborting"
	exit 1
    fi
    cp /opt/cpm/conf/pgadmin-https.conf /etc/httpd/conf.d/pgadmin.conf
else
    echo "TLS disabled.."
    cp /opt/cpm/conf/pgadmin-http.conf /etc/httpd/conf.d/pgadmin.conf
fi

if [[ -f /etc/httpd/conf.d/ssl.conf ]]; then
    mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.disabled
fi

if [[ -f /etc/httpd/conf.d/welcome.conf ]]; then
    mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.disabled
fi

sed -i "s|^User .*|User daemon|g" /etc/httpd/conf/httpd.conf
sed -i "s|^Group .*|Group daemon|g" /etc/httpd/conf/httpd.conf
sed -i "s|SERVER_PORT|${SERVER_PORT:-5050}|g" /etc/httpd/conf.d/pgadmin.conf

cd ${PGADMIN_DIR?}

cp config.py config_local.py
chmod +x config_local.py

sed -i "s/^DEFAULT_SERVER .*/DEFAULT_SERVER = '0.0.0.0'/" config_local.py
sed -i "s/^DEFAULT_SERVER_PORT.*/DEFAULT_SERVER_PORT = ${SERVER_PORT:-5050}/" config_local.py
sed -i "s|    LOG_FILE.*|    LOG_FILE = '/var/lib/pgadmin/pgadmin4.log'|g" config_local.py
sed -i "s|^SQLITE_PATH.*|SQLITE_PATH = '/var/lib/pgadmin/pgadmin4.db'|g" config_local.py
sed -i "s|^SESSION_DB_PATH.*|SESSION_DB_PATH = '/var/lib/pgadmin/sessions'|g" config_local.py
sed -i "s|^STORAGE_DIR.*|STORAGE_DIR = '/var/lib/pgadmin/storage'|g" config_local.py
sed -i "s|^DATA_DIR.*|DATA_DIR = '/var/lib/pgadmin/data'|g" config_local.py
sed -i "s|^UPGRADE_CHECK_ENABLED.*|UPGRADE_CHECK_ENABLED = False|g" config_local.py
sed -i "s|^Listen .*|Listen ${SERVER_PORT:-5050}|g" /etc/httpd/conf/httpd.conf
sed -i "s|\"pg\":.*|\"pg\": \"/usr/pgsql-${PGVERSION?}/bin\",|g" config_local.py

if [[ ! -f /var/lib/pgadmin/pgadmin4.db ]]
then
    echo "Setting up pgAdmin4 database.."
    python setup.py
fi

echo "Starting web server.."
/usr/sbin/httpd -D FOREGROUND
