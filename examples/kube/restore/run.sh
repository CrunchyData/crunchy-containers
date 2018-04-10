#!/bin/bash
# Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
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

export BACKUP_HOST=$($CCP_CLI describe job backup | grep BACKUP_HOST | awk '{print $NF}')
export BACKUP_PATH=$(ls -tc "$CCP_STORAGE_PATH/$BACKUP_HOST-backups/" | head -n1)

if [ ! -z "$CCP_STORAGE_CLASS" ]; then
	echo "CCP_STORAGE_CLASS is set. Using the existing storage class for the PV."
	expenv -f $DIR/restore-pvc-sc.json | ${CCP_CLI?} create -f -
elif [ ! -z "$CCP_NFS_IP" ]; then
	echo "CCP_NFS_IP is set. Creating NFS based storage volumes."
	expenv -f $DIR/restore-pv-nfs.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/restore-pvc.json | ${CCP_CLI?} create -f -
else
	echo "CCP_NFS_IP and CCP_STORAGE_CLASS not set. Creating HostPath based storage volumes."
	expenv -f $DIR/restore-pv.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/restore-pvc.json | ${CCP_CLI?} create -f -
fi

expenv -f $DIR/restore.json | ${CCP_CLI?} create -f -
