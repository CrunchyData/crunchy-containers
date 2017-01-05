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

source "$BUILDBASE"/examples/envvars.sh
NFS_SHARE_IP=${NFS_SHARE_IP:-LOCAL_IP}
NFS_SHARE_PATH=${NFS_SHARE_PATH:-/nfsfileshare}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$DIR"/cleanup.sh
sleep 1

envsubst <  "$DIR"/master-nfs-pv.json | kubectl create -f -
kubectl create -f "$DIR"/master-nfs-pvc.json
envsubst < "$DIR"/master-nfs-pod.json | kubectl create -f -
kubectl create -f "$DIR"/master-nfs-service.json 
