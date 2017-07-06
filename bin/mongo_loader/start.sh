#!/bin/bash  -x

# Copyright 2017 Crunchy Data Solutions, Inc.
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

source /opt/cpm/bin/setenv.sh

if [ ! -v MONGO_HOST ]; then
        echo "MONGO_HOST is not set, required value"
        exit 2
fi
if [ ! -v MONGO_USER ]; then
	echo "MONGO_USER is not set, required value"
	exit 2
fi
if [ ! -v MONGO_DATABASE ]; then
        echo "MONGO_DATABASE is not set, required value"
        exit 2
fi
if [ ! -v MONGO_COLLECTION ]; then
        echo "MONGO_COLLECTION is not set, required value"
        exit 2
fi
if [ ! -v PG_USER ]; then
        echo "PG_USER is not set, required value"
        exit 2
fi
if [ ! -v PG_SERVICE ]; then
        echo "PG_USER is not set, required value"
        exit 2
fi
if [ ! -v PG_DATABASE ]; then
        echo "PG_USER is not set, required value"
        exit 2
fi

# this lets us run the psql cmd  on Openshift
# when it is configured to use random UIDs
# export USER_ID=$(id -u)
# export GROUP_ID=$(id -g)
# envsubst < /opt/cpm/conf/passwd.template > /tmp/passwd
# export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
# export NSS_WRAPPER_PASSWD=/tmp/passwd
# export NSS_WRAPPER_GROUP=/etc/group

echo exporting $MONGO_DATABASE collection $MONGO_COLLECTION

#Perform ETL
mkdir -p /pgloader/mongo

mongoexport -h $MONGO_HOST -u $MONGO_USER -p $MONGO_PWD --authenticationDatabase admin --db $MONGO_DATABASE --collection $MONGO_COLLECTION --out /pgloader/mongo/$MONGO_COLLECTION.json

# Load into PostgreSQL
cp /opt/cpm/bin/mongo_import.sql /tmp/mongo_import.sql

sed -i "s/MONGO_COLLECTION/$MONGO_COLLECTION/g" /tmp/mongo_import.sql

psql -U $PG_USER -h $PG_SERVICE -d $PG_DATABASE -f /tmp/mongo_import.sql

echo "Completed ETL at " `date`
exit 0
