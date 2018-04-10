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

${CCP_CLI?} create configmap primary-deployment-pgconf \
  --from-file=./configs/postgresql.conf \
  --from-file=pghba=./configs/pg_hba.conf \
  --from-file=./configs/setup.sql

if [ ! -z "$CCP_STORAGE_CLASS" ]; then
	echo "CCP_STORAGE_CLASS is set. Using the existing storage class for the PV."
	expenv -f $DIR/primary-deployment-pvc-sc.json | ${CCP_CLI?} create -f -
elif [ ! -z "$CCP_NFS_IP" ]; then
	echo "CCP_NFS_IP is set. Creating NFS based storage volumes."
	expenv -f $DIR/primary-deployment-pv-nfs.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/primary-deployment-pvc.json | ${CCP_CLI?} create -f -
else
	echo "CCP_NFS_IP and CCP_STORAGE_CLASS not set. Creating HostPath based storage volumes."
	expenv -f $DIR/primary-deployment-pv.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/primary-deployment-pvc.json | ${CCP_CLI?} create -f -
fi

expenv -f $DIR/primary-deployment.json | ${CCP_CLI?} create -f -
