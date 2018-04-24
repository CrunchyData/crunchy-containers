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

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USERNAME="$1"
SERVER="$2"

if [[ -z ${USERNAME?} ]] || [[ -z ${SERVER?} ]]
then
    echo "Usage: ssl-creator.sh <CLIENT USERNAME> <SERVER NAME>"
    exit 1
fi

if [[ ! -x "$(command -v certstrap)" ]]
then
    echo "Certstrap is not installed.."
    echo "To install certstrap run: go get github.com/square/certstrap.."
    echo "Exiting.."
    exit 1
fi

certstrap init --common-name RootCA \
  --key-bits 4096 \
  --organization "Crunchy Data" \
  --locality "Charleston" \
  --province "SC" \
  --country "US" \
  --passphrase "" \
  --years 1

certstrap request-cert --passphrase '' --common-name ${SERVER?}
certstrap sign ${SERVER?} --passphrase '' --CA RootCA --years 1

certstrap request-cert --passphrase '' --common-name ${USERNAME?}
certstrap sign ${USERNAME?} --passphrase '' --CA RootCA --years 1

mkdir ${DIR?}/certs

cp ${DIR?}/out/RootCA.crt ${DIR?}/certs/ca.crt
cp ${DIR?}/out/RootCA.crl ${DIR?}/certs/ca.crl

# Server
cp ${DIR?}/out/${SERVER?}.key ${DIR?}/certs/server.key
cat ${DIR?}/out/${SERVER?}.crt ${DIR?}/out/RootCA.crt > ${DIR?}/certs/server.crt

# Client
cp ${DIR?}/out/${USERNAME?}.key ${DIR?}/certs/client.key
cat ${DIR?}/out/${USERNAME?}.crt ${DIR?}/out/RootCA.crt > ${DIR?}/certs/client.crt

chmod 600 ${DIR?}/certs/client.key ${DIR?}/certs/client.crt

exit 0
