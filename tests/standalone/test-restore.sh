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


source $BUILDBASE/tests/standalone/pgpass-setup

#
# test restore
#

$BUILDBASE/examples/standalone/run-restore.sh /tmp/backups/master/2*

sleep 30

psql -p 12001 -h 127.0.0.1 -U masteruser userdb -c 'select now()'

rc=$?

echo $rc is the rc

if [ 0 -eq $rc ]; then
	echo "test restore passed"
else
	echo "test restore FAILED"
	exit $rc
fi

docker stop master-restore
exit 0
