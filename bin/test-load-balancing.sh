#!/bin/bash

# Copyright 2016 - 2019 Crunchy Data Solutions, Inc.
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

/bin/rm -f ./mypgpass
echo "*:*:*:primary:MClNo2g5N8Hu" >> ./mypgpass
export PGPASSFILE=./mypgpass
chmod 400 ./mypgpass

for i in `seq 1 10`;
do
	psql -h pg-replica-rc.pgproject.svc.cluster.local -U primary userdb -c 'select inet_server_addr()'
done
