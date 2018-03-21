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

oc create secret generic pgpool-secrets \
	--from-file=$DIR/pool_hba.conf \
	--from-file=$DIR/pgpool.conf \
	--from-file=$DIR/pool_passwd

oc create configmap pgpool-conf --from-file=pgpool.conf --from-file=hba=pool_hba.conf --from-file=psw=pool_passwd

expenv -f $DIR/pgpool-deployment.json | oc create -f -
oc create -f $DIR/pgpool-service.json
