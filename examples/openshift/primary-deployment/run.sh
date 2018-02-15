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



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

oc create -f $DIR/pguser-secret.json
oc create -f $DIR/pgprimary-secret.json
oc create -f $DIR/pgroot-secret.json

oc create configmap postgresql-conf --from-file=postgresql.conf --from-file=pghba=pg_hba.conf --from-file=setup.sql

oc process -f $DIR/primary-dc.json \
	-p CCP_IMAGE_PREFIX=$CCP_IMAGE_PREFIX  \
	-p CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
#oc process -f $DIR/replica-dc.json -p CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
#oc process -f $DIR/replica2-dc.json -p CCP_IMAGE_TAG=$CCP_IMAGE_TAG | oc create -f -
