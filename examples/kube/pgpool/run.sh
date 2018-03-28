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

echo "This example depends on the primary-replica example being run prior!"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

${CCP_CLI?} create secret generic pgpool-secrets \
	--from-file=$DIR/configs/pool_hba.conf \
	--from-file=$DIR/configs/pgpool.conf \
	--from-file=$DIR/configs/pool_passwd

${CCP_CLI?} create configmap pgpool-pgconf \
	--from-file=./configs/pgpool.conf \
	--from-file=hba=./configs/pool_hba.conf \
	--from-file=psw=./configs/pool_passwd

expenv -f $DIR/pgpool.json | ${CCP_CLI?} create -f -
