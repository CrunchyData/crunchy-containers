#!/bin/bash

# Copyright 2016 - 2020 Crunchy Data Solutions, Inc.
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
PROMETHEUS_VERSION=2.9.2
GRAFANA_VERSION=6.3.4
POSTGRES_EXPORTER_VERSION=0.7.0
PGMONITOR_COMMIT='v3.2'
OPENSHIFT_CLIENT='https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz'
CERTSTRAP_VERSION=1.1.1
YQ_VERSION=2.4.0

sudo yum -y install net-tools bind-utils wget unzip git

#
# download the metrics products, only required to build the containers
#

wget -O $CCPROOT/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
wget -O $CCPROOT/grafana.tar.gz https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz
wget -O $CCPROOT/postgres_exporter.tar.gz https://github.com/wrouesnel/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION?}/postgres_exporter_v${POSTGRES_EXPORTER_VERSION?}_linux-amd64.tar.gz
wget -O $CCPROOT/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64

which buildah
if [ $? -eq 1 ]; then
  echo "installing buildah"

  source /etc/os-release

  if [[ "${VERSION_ID}" == "7" ]]
  then
    cd /etc/yum.repos.d/
    sudo wget https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_7/devel:kubic:libcontainers:stable.repo
    cd $OLDPWD
    sudo yum -y install buildah
  elif [[ "${VERSION_ID}" == "8" ]]
  then
    sudo dnf -y module disable container-tools
    sudo dnf -y install 'dnf-command(copr)'
    sudo dnf -y copr enable rhcontainerbot/container-selinux
    cd /etc/yum.repos.d
    sudo wget https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_8/devel:kubic:libcontainers:stable.repo
    cd $OLDPWD
    sudo dnf -y install buildah
  else
    sudo subscription-manager repos --enable=rhel-7-server-extras-rpms
    sudo yum -y install buildah
  fi
fi

FILE='openshift-origin-client.tgz'
wget -O /tmp/${FILE?} ${OPENSHIFT_CLIENT?}
tar xvzf /tmp/${FILE?} -C /tmp
sudo cp /tmp/openshift-*/oc /usr/bin/oc

# Install dep
go get github.com/golang/dep/cmd/dep

# install expenv binary for running examples
go get github.com/blang/expenv

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
