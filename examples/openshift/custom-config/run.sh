#!/bin/bash

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


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

sudo cp $DIR/setup.sql $PV_PATH
sudo cp $DIR/pg_hba.conf $PV_PATH
sudo cp $DIR/postgresql.conf $PV_PATH
sudo chown nfsnobody:nfsnobody $PV_PATH/setup.sql $PV_PATH/postgresql.conf \
$PV_PATH/pg_hba.conf
sudo chmod g+r $PV_PATH/setup.sql $PV_PATH/postgresql.conf $PV_PATH/pg_hba.conf

oc process -f $DIR/custom-config.json -p CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
