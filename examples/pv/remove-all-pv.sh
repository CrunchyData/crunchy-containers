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

$CCP_CLI delete pv $($CCP_CLI get pv | cut -f1 -d' ')

if hash gcloud 2>/dev/null; then
	end_disk=""
	for i in {1..3}
	do
		export COUNTER=$i
		disk="$GCE_DISK_NAME-$COUNTER"
		end_disk="$disk $end_disk"
	done
	gcloud compute disks delete $end_disk << EOF 
EOF
fi