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

# Dependency Versions
PROMETHEUS_VERSION=2.2.0
GRAFANA_VERSION=4.6.3
POSTGRES_EXPORTER_VERSION=0.4.4
NODE_EXPORTER_VERSION=0.15.2
MERCURIAL_RPM='https://www.mercurial-scm.org/release/centos7/RPMS/x86_64/mercurial-4.6.1-1.x86_64.rpm'

sudo yum -y install net-tools bind-utils wget unzip git

#
# download the metrics products, only required to build the containers
#

wget -O $CCPROOT/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
wget -O $CCPROOT/grafana.tar.gz https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-${GRAFANA_VERSION}.linux-x64.tar.gz
wget -O $CCPROOT/postgres_exporter.tar.gz https://github.com/wrouesnel/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION?}/postgres_exporter_v${POSTGRES_EXPORTER_VERSION?}_linux-amd64.tar.gz
wget -O $CCPROOT/node_exporter.tar.gz https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

rpm -q atomic-openshift-clients
if [ $? -ne 0 ]; then
    echo "atomic-openshift-clients is NOT installed"
    sudo yum list available | grep atomic-openshift-clients
    if [ $? -ne 0 ]; then
        echo atomic-openshift-clients package is NOT found
        sudo yum -y install kubernetes-client
        FILE=openshift-origin-client-tools-v3.7.0-7ed6862-linux-64bit.tar.gz
        wget -O /tmp/$FILE \
        https://github.com/openshift/origin/releases/download/v3.7.0/$FILE

        tar xvzf /tmp/$FILE  -C /tmp
        sudo cp /tmp/openshift-origin-client-tools-v3.7.0-7ed6862-linux-64bit/oc /usr/bin/oc
    else
        echo atomic-openshift-clients package IS found
        sudo yum -y install atomic-openshift-clients
    fi

fi

# install expenv binary for running examples
go get github.com/blang/expenv
go get github.com/square/certstrap

# pull in godeps and the dependencies for the golang code
go get github.com/tools/godep
sudo yum -y install ${MERCURIAL_RPM?}

godep restore
