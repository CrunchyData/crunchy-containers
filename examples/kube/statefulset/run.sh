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

# As of Kube 1.6, it is necessary to allow the service account to perform
# a label command. For this example, we open up wide permissions
# for all serviceaccounts. This is NOT for production!

${CCP_CLI?} create clusterrolebinding statefulset-sa \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts \
  --namespace=$CCP_NAMESPACE

if [ ! -z "$CCP_STORAGE_CLASS" ]; then
	echo "CCP_STORAGE_CLASS is set. Using the existing storage class for the PV."
	expenv -f $DIR/statefulset-pvc-sc.json | ${CCP_CLI?} create -f -
elif [ ! -z "$CCP_NFS_IP" ]; then
	echo "CCP_NFS_IP is set. Creating NFS based storage volumes."
	expenv -f $DIR/statefulset-pv-nfs.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/statefulset-pvc.json | ${CCP_CLI?} create -f -
else
	echo "CCP_NFS_IP and CCP_STORAGE_CLASS not set. Creating HostPath based storage volumes."
	expenv -f $DIR/statefulset-pv.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/statefulset-pvc.json | ${CCP_CLI?} create -f -
fi

  expenv -f $DIR/statefulset.json | ${CCP_CLI?} create -f -
