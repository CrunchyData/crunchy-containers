

#
# next set is only for setting up enterprise crunchy postgres repo
# not required if you build on centos
#
sudo mkdir /opt/crunchy
sudo cp $CCPROOT/conf/crunchypg95.repo /etc/yum.repos.d
sudo cp $CCPROOT/conf/CRUNCHY* /opt/crunchy
sudo yum -y install postgresql95-server

sudo yum -y install net-tools bind-utils wget unzip git 

#
wget -O $CCPROOT/prometheus-pushgateway.tar.gz https://github.com/prometheus/pushgateway/releases/download/v0.3.1/pushgateway-0.3.1.linux-amd64.tar.gz
wget -O $CCPROOT/prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v1.5.2/prometheus-1.5.2.linux-amd64.tar.gz
wget -O $CCPROOT/grafana.tar.gz https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.2.0.linux-x64.tar.gz


# Install a specific set of gems in order to get asciidoctor-pdf.
sudo yum -y install postgresql-server

