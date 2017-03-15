

#
# next set is only for setting up enterprise crunchy postgres repo
# not required if you build on centos
#
sudo mkdir /opt/crunchy
sudo cp $BUILDBASE/conf/crunchypg95.repo /etc/yum.repos.d
sudo cp $BUILDBASE/conf/CRUNCHY* /opt/crunchy
sudo yum -y install postgresql95-server

sudo yum -y install net-tools bind-utils wget unzip git golang

#
# download the pgadmin4 python wheel distro
#
wget https://ftp.postgresql.org/pub/pgadmin3/pgadmin4/v1.1/pip/pgadmin4-1.1-py2-none-any.whl
#
# download the metrics products, only required to build the containers
#
wget -O $BUILDBASE/prometheus-pushgateway.tar.gz https://github.com/prometheus/pushgateway/releases/download/0.3.0/pushgateway-0.3.0.linux-amd64.tar.gz
wget -O $BUILDBASE/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v1.1.2/prometheus-1.1.2.linux-amd64.tar.gz
wget -O $BUILDBASE/grafana.tar.gz https://grafanarel.s3.amazonaws.com/builds/grafana-3.1.1-1470047149.linux-x64.tar.gz
wget -O /tmp/consul_0.6.4_linux_amd64.zip https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip
unzip /tmp/consul*.zip -d /tmp
rm /tmp/consul*.zip
mv /tmp/consul $GOBIN

#
# this set is required to build the docs
#
sudo yum -y install asciidoc ruby

# Install a slightly older version of prawn.  Prawn dependency ttfunk 1.5.0 requires Ruby >= 2.1.
# Prawn 2.1.0 is the latest version which is still compatible with Ruby 2.0.0 supported by RHEL 7
gem install prawn -v 2.1.0
gem install --minimal-deps --pre asciidoctor-pdf

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

sudo yum -y install postgresql-server

#
# install kubectl binary into /usr/bin
#
sudo yum -y install kubernetes-client
fi
