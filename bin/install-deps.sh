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

sudo yum -y install net-tools bind-utils wget unzip git golang postgresql

#
# download the metrics products, only required to build the containers
#
wget -O $CCPROOT/prometheus-pushgateway.tar.gz https://github.com/prometheus/pushgateway/releases/download/v0.3.1/pushgateway-0.3.1.linux-amd64.tar.gz
wget -O $CCPROOT/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v1.5.2/prometheus-1.5.2.linux-amd64.tar.gz
wget -O $CCPROOT/grafana.tar.gz https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.2.0.linux-x64.tar.gz

#
# this set is required to build the docs
#
sudo yum -y install asciidoc ruby

# Install a specific set of gems in order to get asciidoctor-pdf.
# Note that "gem install --pre asciidoctor-pdf" may not work because prawn dependency ttfunk 1.5.0 requires Ruby >= 2.1.
# Prawn 2.1.0 is the latest version which is still compatible with Ruby 2.0.0 supported by RHEL 7
gem install --minimal-deps ttfunk -v 1.4.0
gem install --minimal-deps pdf-core -v 0.6.1
gem install --minimal-deps prawn -v 2.1.0
gem install --minimal-deps asciidoctor -v 1.5.5
gem install --minimal-deps prawn-table -v 0.2.2
gem install --minimal-deps Ascii85 -v 1.0.2
gem install --minimal-deps ruby-rc4 -v 0.1.5
gem install --minimal-deps hashery -v 2.1.2
gem install --minimal-deps afm -v 0.2.2
gem install --minimal-deps pdf-reader -v 1.4.1
gem install --minimal-deps prawn-templates -v 0.0.3
gem install --minimal-deps public_suffix -v 2.0.5
gem install --minimal-deps addressable -v 2.5.0
gem install --minimal-deps css_parser -v 1.4.10
gem install --minimal-deps prawn-svg -v 0.26.0
gem install --minimal-deps prawn-icon -v 1.3.0
gem install --minimal-deps safe_yaml -v 1.0.4
gem install --minimal-deps thread_safe -v 0.3.6
gem install --minimal-deps polyglot -v 0.3.5
gem install --minimal-deps treetop -v 1.5.3
gem install --minimal-deps --no-ri asciidoctor-pdf -v 1.5.0.alpha.14

wget -O $HOME/bootstrap-4.5.0.zip http://laurent-laville.org/asciidoc/bootstrap/bootstrap-4.5.0.zip
asciidoc --backend install $HOME/bootstrap-4.5.0.zip
mkdir -p $HOME/.asciidoc/backends/bootstrap/js
cp $GOPATH/src/github.com/crunchydata/crunchy-containers/docs/bootstrap.js \
$HOME/.asciidoc/backends/bootstrap/js/
unzip $HOME/bootstrap-4.5.0.zip  $HOME/.asciidoc/backends/bootstrap/

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

#
# install kubectl binary into /usr/bin
#
sudo yum -y install kubernetes-client
fi
