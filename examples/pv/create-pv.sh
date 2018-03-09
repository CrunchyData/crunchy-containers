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

function cleanup {
	for i in {1..100}
	do
		echo "deleting PV crunchy-pv$i"
		$CCP_CLI delete pv crunchy-pv$i
	done
}

if [ "$1" == "hostpath" ]; then
	cleanup
	echo "creating hostPath PVs"
	for i in {1..100}
	do
		echo "creating PV crunchy-pv$i"
		export COUNTER=$i
		expenv -f $DIR/hostpath/crunchy-pv.json | $CCP_CLI create -f -
	done
elif [ "$1" == "nfs" ]; then
	cleanup
	echo "creating NFS PVs"
	for i in {1..100}
	do
		echo "creating PV crunchy-pv$i"
		export COUNTER=$i
		expenv -f $DIR/nfs/crunchy-pv.json | $CCP_CLI create -f -
	done
elif [ "$1" == "gce" ]; then
	cleanup
	echo "cleanup disks gce"
	for i in {1..3}
	do
		export COUNTER=$i
		disk="$GCE_DISK_NAME-$COUNTER"
		end_disk="$disk $end_disk"
	done
	gcloud compute disks delete $end_disk << EOF
EOF
	echo "creating gcePersistentDisk PVs"
	for i in {1..3}
	do
		FS_FORMAT="ext4"
		echo "creating PV crunchy-pv$i"
		export COUNTER=$i
		gcloud compute disks create "$GCE_DISK_NAME-$COUNTER" --size=$GCE_DISK_SIZE"GB" --zone=$GCE_DISK_ZONE
		expenv -f $DIR/gce/crunchy-pv.json | $CCP_CLI create -f -
	done
else
	echo "Command Line Arguments:"
	for i in "- hostpath" "- nfs" "- gce"
	do
		echo $i
	done
fi
