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

echo -e "\nTesting pgaudit..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOW=$(date +%u)

if [[ $DOW == 7 ]]; then
	DAY=Sun
elif [[ $DOW == 1 ]]; then
	DAY=Mon
elif [[ $DOW == 2 ]]; then
        DAY=Tue
elif [[ $DOW == 3 ]]; then
        DAY=Wed
elif [[ $DOW == 4 ]]; then
        DAY=Thu
elif [[ $DOW == 5 ]]; then
        DAY=Fri
elif [[ $DOW == 6 ]]; then
        DAY=Sat
fi

export PGPASSWORD=password

svc="$(kubectl get svc pgaudit | grep -v CLUSTER-IP )"
svcIP="$(echo $svc | awk {'print $3'})"

psql -h $svcIP -U postgres -f $DIR/test.sql postgres
echo -e "\nTest SQL written to pgaudit."
sleep 2

kubectl exec pgaudit -- grep AUDIT /pgdata/pgaudit/pg_log/postgresql-$DAY.log

if [ $? -ne 0 ]; then
	echo -e "\nTest failed. No AUDIT messages were found in the PostgreSQL log file."
	exit 1
fi
echo -e "\nTest passed. AUDIT messages were found in the PostgreSQL log file."
