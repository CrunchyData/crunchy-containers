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

set -u

source "$BUILDBASE"/examples/envvars.sh

export NFS_SHARE_PATH=${NFS_SHARE_PATH:-/nfsfileshare}
export NFS_SHARE_SERVER=${NFS_SHARE_SERVER:-$LOCAL_IP}

# set the root path to the basic pod nfs share
if [ "$NFS_SHARE_SERVER" != "$LOCAL_IP" ]; then
	MNT=$(mktemp -d /tmp/XXXX)
	sudo mount -t nfs "$NFS_SHARE_SERVER:$NFS_SHARE_PATH" $MNT
	BASIC_SHARE_ROOT=$MNT/basic
else
	BASIC_SHARE_ROOT="$NFS_SHARE_PATH"/basic
fi

# remove old backup directories from basic pod nfs share
sudo find "$BASIC_SHARE_ROOT" -type d -regextype sed \
 -regex "^$BASIC_SHARE_ROOT\/20[1-3][0-9]-[0-1][0-9]-[0-3][0-9]-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}$" \
 -exec rm -rf {} \;

# start basic container and backup job
source "$BUILDBASE"/tests/kubernetes/pgpass-setup

echo "starting Crunchy Postgres"
"$BUILDBASE"/examples/kube/basic/run.sh
sleep 30

echo "starting Crunchy backup job"
"$BUILDBASE"/examples/kube/backup-job/run.sh
sleep 20

find "$BASIC_SHARE_ROOT" -type f -regextype sed \
 -regex "^$BASIC_SHARE_ROOT\/20[1-3][0-9]-[0-1][0-9]-[0-3][0-9]-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}/postgresql.conf$" > /dev/null
rc=$?

if [ "$NFS_SHARE_SERVER" != "$LOCAL_IP" ]; then
	sudo umount $MNT
	rm -rf $MNT
fi

if [ 0 -eq $rc ]; then
	echo "kubernetes backup-job test passed"
else
	echo "Kubernetes backub-job test FAILED with $rc"
	exit $rc
fi

exit 0
