#!/bin/bash  -x

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

echo STANZA $STANZA set
if [ ! -v STANZA ]; then
	echo "STANZA env var is not set, required value"
	exit 2
fi

echo "Starting restore. Examine restore log in /backrestrepo for results" `date`

# this lets us run the pgbackrest cmd  on Openshift
# when it is configured to use random UIDs
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /opt/cpm/conf/passwd.template > /tmp/passwd
export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group


if [ -v DELTA ]; then
    pgbackrest --config=/pgconf/pgbackrest.conf --stanza=$STANZA --log-path=/backrestrepo --delta restore
else
    pgbackrest --config=/pgconf/pgbackrest.conf --stanza=$STANZA --log-path=/backrestrepo restore
fi

echo "Completed restore at " `date`
exit 0
