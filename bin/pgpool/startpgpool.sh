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

# clean up leftovers from previous runs of pgpool
rm -rf /tmp/pgpool.pid
rm -rf /tmp/.s.*

env

BINDIR=/opt/cpm/bin
CONFDIR=/opt/cpm/conf/pgpool

cp $CONFDIR/* /tmp

function check_for_overrides() {
        if [ -f /pgconf/pgpool.conf ]; then
                echo "pgconf pgpool.conf is being used"
		cp /pgconf/pgpool.conf /tmp
        fi
        if [ -f /pgconf/pool_hba.conf ]; then
                echo "pgconf pool_hba.conf is being used"
		cp /pgconf/pool_hba.conf /tmp
        fi
}

# populate template with env vars
sed -i "s/PG_MASTER_SERVICE_NAME/$PG_MASTER_SERVICE_NAME/g" /tmp/pgpool.conf
sed -i "s/PG_SLAVE_SERVICE_NAME/$PG_SLAVE_SERVICE_NAME/g" /tmp/pgpool.conf
sed -i "s/PG_USERNAME/$PG_USERNAME/g" /tmp/pgpool.conf
sed -i "s/PG_PASSWORD/$PG_PASSWORD/g" /tmp/pgpool.conf

# populate pool_passwd file
/bin/pg_md5 --md5auth --username=$PG_USERNAME --config=/tmp/pgpool.conf $PG_PASSWORD

check_for_overrides

/bin/pgpool -n -a /tmp/pool_hba.conf -f /tmp/pgpool.conf 
