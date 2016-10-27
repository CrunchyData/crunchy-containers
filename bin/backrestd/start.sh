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

source /opt/cpm/bin/setenv.sh

export PG_MODE=$PG_MODE
export PG_MASTER_HOST=$PG_MASTER_HOST
export PG_MASTER_PORT=$PG_MASTER_PORT
export PG_MASTER_USER=$PG_MASTER_USER
export PG_MASTER_PASSWORD=$PG_MASTER_PASSWORD
export PG_USER=$PG_USER
export PG_PASSWORD=$PG_PASSWORD
export PG_DATABASE=$PG_DATABASE
export PG_ROOT_PASSWORD=$PG_ROOT_PASSWORD

/usr/sbin/sshd -f /pgconf/sshd_config

while true; do
	echo "debug sleeping should never get here!! remove for production"
	sleep 1000
done
