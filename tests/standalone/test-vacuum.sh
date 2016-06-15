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



echo BUILDBASE is $BUILDBASE

#
# test backup
#

$BUILDBASE/examples/standalone/run-vacuum.sh

sleep 10

docker logs crunchy-vacuum-job | grep VACUUM

rc=$?
if [ 0 -eq $rc ]; then
	echo vacuum test passed
	exit 0
else
	echo vacuum test FAILED
	exit 1
fi

exit 1
