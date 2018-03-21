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

openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 5 -nodes -subj '/CN=localhost'

oc create secret generic pgadmin-secrets \
    --from-literal=pgadmin-email='admin@admin.com' \
    --from-literal=pgadmin-password='password'

oc create secret generic pgadmin-tls \
    --from-file=pgadmin-cert=${DIR?}/server.crt\
    --from-file=pgadmin-key=${DIR?}/server.key

expenv -f $DIR/pgadmin4.json | oc create -f -
