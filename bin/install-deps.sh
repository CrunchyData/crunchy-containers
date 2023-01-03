#!/bin/bash

# Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
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

# Dependency Versions
PGMONITOR_COMMIT='v4.5-RC3'
OPENSHIFT_CLIENT='https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz'
CERTSTRAP_VERSION=1.1.1
YQ_VERSION=3.3.0

sudo yum -y install net-tools bind-utils wget unzip git

which buildah
if [ $? -eq 1 ]; then
        echo "installing buildah"
        sudo subscription-manager repos --enable=rhel-7-server-extras-rpms
        sudo yum -y install buildah
fi

FILE='openshift-origin-client.tgz'
wget -O /tmp/${FILE?} ${OPENSHIFT_CLIENT?}
tar xvzf /tmp/${FILE?} -C /tmp
sudo cp /tmp/openshift-*/oc /usr/bin/oc

# manually install certstrap into $GOBIN for running the SSL examples
wget -O $CCPROOT/certstrap https://github.com/square/certstrap/releases/download/v${CERTSTRAP_VERSION}/certstrap-v${CERTSTRAP_VERSION}-linux-amd64 && \
    mv $CCPROOT/certstrap $GOBIN && \
    chmod +x $GOBIN/certstrap

# pgMonitor Setup
if [[ -d ${CCPROOT?}/tools/pgmonitor ]]
then
    rm -rf ${CCPROOT?}/tools/pgmonitor
fi
git clone https://github.com/CrunchyData/pgmonitor.git ${CCPROOT?}/tools/pgmonitor
cd ${CCPROOT?}/tools/pgmonitor
git checkout ${PGMONITOR_COMMIT?}
