#!/bin/bash -x

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

#
# set up some env vars that all examples can relate to
#

export CCP_CLI=oc
#export CCP_CLI=kubectl
export NAMESPACE=demo-project
export PV_PATH=/nfsfileshare
#export PV_PATH=/data
export GCE_DISK_ZONE=us-central1-a
export GCE_DISK_NAME=gce-disk-crunchy
export GCE_DISK_SIZE=4
export GCE_FS_FORMAT=ext4
export NFS_IP=`hostname --ip-address`
export LOCAL_IP=`hostname --ip-address`

if [ -v $CCP_IMAGE_TAG ]; then
	export CCP_IMAGE_TAG=centos7-9.6.5-1.6.0
	echo "CCP_IMAGE_TAG was not found...using current tag of " $CCP_IMAGE_TAG
fi

# for PVC templates - NFS uses ReadWriteMany - EBS uses ReadWriteOnce

# for templates - allow for override of Image Path Prefix
export CCP_IMAGE_PREFIX=172.30.170.83:5000/demo-project
export REPLACE_CCP_IMAGE_PREFIX=crunchydata
#export CCP_IMAGE_PREFIX=crunchydata
