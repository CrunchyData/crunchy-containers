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
CONFIGS=/tmp

function trap_sigterm() {
	echo "doing trap logic..."
	kill -SIGINT $PGPOOL_PID
}

trap 'trap_sigterm' SIGINT SIGTERM


# seed with defaults included in the container image, this is the
# case when /pgconf is not specified
cp $CONFDIR/* /tmp

if [ -f /pgconf/pgpoolconfigdir/pgpool.conf ]; then
	echo "pgconf pgpool.conf is being used"
	CONFIGS=/pgconf/pgpoolconfigdir
fi

# populate template with env vars
sed -i "s/PG_MASTER_SERVICE_NAME/$PG_MASTER_SERVICE_NAME/g" $CONFIGS/pgpool.conf
sed -i "s/PG_SLAVE_SERVICE_NAME/$PG_SLAVE_SERVICE_NAME/g" $CONFIGS/pgpool.conf
sed -i "s/PG_USERNAME/$PG_USERNAME/g" $CONFIGS/pgpool.conf
sed -i "s/PG_PASSWORD/$PG_PASSWORD/g" $CONFIGS/pgpool.conf

# populate pool_passwd file
/bin/pg_md5 --md5auth --username=$PG_USERNAME --config=$CONFIGS/pgpool.conf $PG_PASSWORD

/bin/pgpool -n -a $CONFIGS/pool_hba.conf -f $CONFIGS/pgpool.conf  &
export PGPOOL_PID=$!

echo "waiting for pgpool to be signaled..."
wait

#while true; do
#       echo "debug sleeping..."
#       sleep 1000
#done

