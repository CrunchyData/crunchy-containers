#!/bin/bash -x


# Copyright 2015 Crunchy Data Solutions, Inc.
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

if [ -v BADGER_TARGET ]; then
	echo "BADGER_TARGET is set ...this is the standalone case"
	/bin/pgbadger -o /tmp/badger.html /pgdata/$BADGER_TARGET/pg_log/*.log
else
	echo "this is the openshift case"
	/bin/pgbadger -o /tmp/badger.html /pgdata/$HOSTNAME/pg_log/*.log
fi

