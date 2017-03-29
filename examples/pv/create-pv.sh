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

source $CCPROOT/examples/envvars.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$CCP_CLI delete pv crunchy-pv crunchy-pv2 crunchy-pv3 master-dba-backup-pv

if [ "$1" == "hostpath" ]; then
	echo "creating hostPath PVs"
	envsubst < $DIR/hostpath/crunchy-pv.json |  $CCP_CLI create -f -
	envsubst < $DIR/hostpath/crunchy-pv2.json |  $CCP_CLI create -f -
	envsubst < $DIR/hostpath/crunchy-pv3.json |  $CCP_CLI create -f -
	envsubst < $DIR/hostpath/crunchy-pv-backup.json |  $CCP_CLI create -f -
else
	echo "creating NFS PVs"
	envsubst < $DIR/nfs/crunchy-pv.json |  $CCP_CLI create -f -
	envsubst < $DIR/nfs/crunchy-pv2.json |  $CCP_CLI create -f -
	envsubst < $DIR/nfs/crunchy-pv3.json |  $CCP_CLI create -f -
	envsubst < $DIR/nfs/crunchy-pv-backup.json |  $CCP_CLI create -f -
fi

