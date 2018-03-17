#!/bin/bash 

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
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

echo "test pgaudit..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

psql -h localhost -p 12005 -U postgres -f $DIR/test.sql postgres

docker exec audittest /bin/sh -c 'grep AUDIT /pgdata/audittest/pg_log/post*.log'

if [ $? -ne 0 ]; then
	echo "test failed...no AUDIT msgs were found in the log file"
	exit 1
fi
echo "test passed, AUDIT msgs were found in the postgres log file"
