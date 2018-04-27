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

source /opt/cpm/bin/common_lib.sh

#export PGPASSFILE=/tmp/pgpass
#
# $1 is the HOSTNAME
# $2 is the PG PORT
# $3 is the PG USER

echo_info "Initializing pgbench database.."
psql -p $2 -h $1 -c 'create database pgbench' -U $3 postgres
pgbench --host=$1 \
	--port=$2 \
	--username=$3 \
	--scale=5 \
	--initialize pgbench

echo_info "Adding some load.."
pgbench --host=$1 \
	--port=$2 \
	--username=$3 \
	--time=10 \
	--client=15 \
	pgbench
