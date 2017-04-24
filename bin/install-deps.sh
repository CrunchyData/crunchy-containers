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

sudo yum -y install net-tools bind-utils wget unzip git postgresql

#sudo yum -y install golang

#
# download the metrics products, only required to build the containers
#
wget -O $CCPROOT/prometheus-pushgateway.tar.gz https://github.com/prometheus/pushgateway/releases/download/v0.3.1/pushgateway-0.3.1.linux-amd64.tar.gz
wget -O $CCPROOT/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v1.5.2/prometheus-1.5.2.linux-amd64.tar.gz
wget -O $CCPROOT/grafana.tar.gz https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.2.0.linux-x64.tar.gz


sudo yum -y install atomic-openshift-client kubernetes-client

rpm -qa | grep atomic-openshift-client
if [ $? -ne 0 ]; then
#
# install oc binary into /usr/bin
#

FILE=openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz
wget -O /tmp/$FILE \
https://github.com/openshift/origin/releases/download/v1.4.1/$FILE

tar xvzf /tmp/$FILE  -C /tmp
sudo cp /tmp/openshift-origin-client-tools-v1.4.1+3f9807a-linux-64bit/oc /usr/bin/oc

fi
