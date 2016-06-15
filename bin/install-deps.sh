
sudo yum -y install net-tools bind-utils wget unzip git golang
sudo mkdir /opt/crunchy
sudo cp $BUILDBASE/conf/crunchypg95.repo /etc/yum.repos.d
sudo cp $BUILDBASE/conf/CRUNCHY* /opt/crunchy
sudo yum -y install postgresql95-server
wget -O $BUILDBASE/prometheus-pushgateway.tar.gz https://github.com/prometheus/pushgateway/releases/download/0.2.0/pushgateway-0.2.0.linux-amd64.tar.gz
wget -O $BUILDBASE/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/0.17.0/prometheus-0.17.0.linux-amd64.tar.gz 
wget -O $BUILDBASE/grafana.tar.gz  https://grafanarel.s3.amazonaws.com/builds/grafana-2.6.0.linux-x64.tar.gz
wget -O /tmp/consul_0.6.4_linux_amd64.zip https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip
unzip /tmp/consul*.zip -d /tmp
rm /tmp/consul*.zip
mv /tmp/consul $GOBIN

yum -y install asciidoc ruby
gem install --pre asciidoctor-pdf
wget -O $HOME/bootstrap-4.5.0.zip http://laurent-laville.org/asciidoc/bootstrap/bootstrap-4.5.0.zip
asciidoc --backend install $HOME/bootstrap-4.5.0.zip
mkdir -p $HOME/.asciidoc/backends/bootstrap/js
cp $GOPATH/src/github.com/crunchydata/crunchy-containers/docs/bootstrap.js \
$HOME/.asciidoc/backends/bootstrap/js/

wget -O /tmp/openshift-origin-client-tools-v1.1.3-cffae05-linux-64bit.tar.gz \
https://github.com/openshift/origin/releases/download/v1.1.3/openshift-origin-client-tools-v1.1.3-cffae05-linux-64bit.tar.gz
tar xvzf /tmp/openshift-origin-client-tools-v1.1.3-cffae05-linux-64bit.tar.gz  -C /tmp
sudo cp /tmp/openshift-origin-client-tools-v1.1.3-cffae05-linux-64bit/oc /usr/bin/oc

sudo yum -y install postgresql-server
