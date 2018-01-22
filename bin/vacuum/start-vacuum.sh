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

echo $PG_USER is PG_USER
if [ ! -v PG_USER ]; then
	echo "PG_USER env var is not set, required value"
	exit 2
fi
echo $PG_PASSWORD is PG_PASSWORD
if [ ! -v PG_PASSWORD ]; then
	echo "PG_PASSWORD env var is not set, required value"
	exit 2
fi
echo $JOB_HOST is JOB_HOST
if [ ! -v JOB_HOST ]; then
	echo "JOB_HOST env var is not set, required value"
	exit 2
fi


/opt/cpm/bin/vacuum
