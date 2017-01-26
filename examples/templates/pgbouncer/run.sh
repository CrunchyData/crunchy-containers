#!/bin/bash

# Copyright 2016 Crunchy Data Solutions, Inc.
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

source $BUILDBASE/examples/envvars.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

CONFIGDIR=/nfsfileshare/bouncerconfig

sudo rm -rf $CONFIGDIR
sudo mkdir $CONFIGDIR
sudo chmod 777 $CONFIGDIR

cp $DIR/pgbouncer.ini $CONFIGDIR
cp $DIR/users.txt $CONFIGDIR

TMPFILE=/tmp/pgbouncer-pv.json
cp $DIR/pgbouncer-pv.json $TMPFILE
sed -i "s/REPLACE_LOCAL_IP/$LOCAL_IP/g" $TMPFILE
oc create -f $TMPFILE

TMPFILE=/tmp/pgbouncer.json
cp $DIR/pgbouncer.json $TMPFILE
sed -i "s/REPLACE_CCP_IMAGE_TAG/$CCP_IMAGE_TAG/g" $TMPFILE
sed -i "s/REPLACE_CCP_IMAGE_PREFIX/$CCP_IMAGE_PREFIX/g" $TMPFILE
oc create -f $TMPFILE

