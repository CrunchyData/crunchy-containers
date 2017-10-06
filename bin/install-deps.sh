#!/bin/bash

# Copyright 2017 Crunchy Data Solutions, Inc.
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
PROM_GATEWAY_VERSION=0.3.1
PROMETHEUS_VERSION=1.5.2
GRAFANA_VERSION=4.5.1
POSTGRES_EXPORTER_VERSION=0.2.3
NODE_EXPORTER_VERSION=0.14.0

sudo yum -y install net-tools bind-utils wget unzip git postgresql

#
# download the metrics products, only required to build the containers
#
wget -O $CCPROOT/prometheus-pushgateway.tar.gz https://github.com/prometheus/pushgateway/releases/download/v${PROM_GATEWAY_VERSION}/pushgateway-${PROM_GATEWAY_VERSION}.linux-amd64.tar.gz
wget -O $CCPROOT/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
wget -O $CCPROOT/grafana.tar.gz https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-${GRAFANA_VERSION}.linux-x64.tar.gz
wget -O $CCPROOT/postgres_exporter https://github.com/wrouesnel/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION}/postgres_exporter
wget -O $CCPROOT/node_exporter.tar.gz https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# Ensure file modes
chmod +x postgres_exporter

#
# download postage source package, required to build the container
#
wget -O $CCPROOT/postage.tar.gz https://github.com/workflowproducts/postage/archive/eV3.2.16.tar.gz

#
# this set is required to build the docs with a2x
#
sudo yum -y install asciidoc ruby
sudo yum -y install lynx dblatex

wget -O $HOME/bootstrap-4.5.0.zip http://laurent-laville.org/asciidoc/bootstrap/bootstrap-4.5.0.zip
asciidoc --backend install $HOME/bootstrap-4.5.0.zip
mkdir -p $HOME/.asciidoc/backends/bootstrap/js
cp $GOPATH/src/github.com/crunchydata/crunchy-containers/docs/bootstrap.js \
$HOME/.asciidoc/backends/bootstrap/js/
unzip $HOME/bootstrap-4.5.0.zip  $HOME/.asciidoc/backends/bootstrap/

sudo yum -y install atomic-openshift-client kubernetes-client

rpm -qa | grep atomic-openshift-client
if [ $? -ne 0 ]; then
#
# install oc binary into /usr/bin
#

FILE=openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz
wget -O /tmp/$FILE \
https://github.com/openshift/origin/releases/download/v1.5.1/$FILE

tar xvzf /tmp/$FILE  -C /tmp
sudo cp /tmp/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit/oc /usr/bin/oc

fi

#
# Install libstatgrab dependencies for collectapi container
#

sudo yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/l/log4cplus-1.1.3-0.4.rc3.el7.x86_64.rpm
sudo yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/l/log4cplus-devel-1.1.3-0.4.rc3.el7.x86_64.rpm
sudo yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/l/libstatgrab-0.91-4.el7.x86_64.rpm
sudo yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/l/libstatgrab-devel-0.91-4.el7.x86_64.rpm
sudo yum -y install gcc
