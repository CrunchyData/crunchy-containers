#!/bin/bash  -x

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

date

source /opt/cpm/bin/setenv.sh

echo STANZA $STANZA set
if [ ! -v STANZA ]; then
	echo "STANZA env var is not set, required value"
	exit 2
fi

echo "Starting restore. Examine restore log in /backrestrepo for results"

pgbackrest --config=/pgconf/pgbackrest.conf --stanza=$STANZA --log-path=/backrestrepo restore
