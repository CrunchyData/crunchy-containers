#!/bin/bash
# Copyright 2018 Crunchy Data Solutions, Inc.
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

$DIR/cleanup-pgpool.sh

POOLDIR=$CCP_STORAGE_PATH/pgpoolconfigdir
sudo mkdir $POOLDIR
sudo chown daemon:daemon $POOLDIR
sudo chmod 777 $POOLDIR
sudo cp pgpool.conf $POOLDIR
sudo cp pool_passwd $POOLDIR
sudo cp pool_hba.conf $POOLDIR

expenv -f $DIR/pgpool-pod.json | oc create -f -
oc create -f $DIR/pgpool-service.json
