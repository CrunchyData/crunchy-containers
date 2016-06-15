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
# test backup
#

sudo rm -rf /tmp/backups/master

$BUILDBASE/examples/standalone/run-backup.sh

sleep 20

FILE=/tmp/backups/master/2*/postgresql.conf

if [ -f $FILE ]; then
        echo "test backup passed"
	exit 0
fi

echo "test backup FAILED"
exit 1
