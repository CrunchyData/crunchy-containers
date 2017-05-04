#!/bin/bash

# Copyright 2017 Crunchy Data Solutions, Inc.
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

if [ -d /usr/pgsql-9.6 ]; then
	export PGROOT=/usr/pgsql-9.6
elif [ -d /usr/pgsql-9.5 ]; then
	export PGROOT=/usr/pgsql-9.5
elif [ -d /usr/pgsql-9.4 ]; then
	export PGROOT=/usr/pgsql-9.4
else
	export PGROOT=/usr/pgsql-9.3
fi

echo "setting PGROOT to " $PGROOT

export PGDATA=/pgdata/$HOSTNAME
export PGWAL=/pgwal/$HOSTNAME-wal

if [[ -v PGDATA_PATH_OVERRIDE ]]; then
	export PGDATA=/pgdata/$PGDATA_PATH_OVERRIDE
	export PGWAL=/pgwal/$PGDATA_PATH_OVERRIDE-wal
fi

export PATH=/opt/cpm/bin:$PGROOT/bin:$PATH
export LD_LIBRARY_PATH=$PGROOT/lib

chown postgres $PGDATA $PGWAL
