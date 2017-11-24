#!/bin/bash
# Prepare for OSE install
function setup-repos {
	echo "Setting up repositories and updating the system..."
	sudo subscription-manager repos --disable="*"
	sudo subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-optional-rpms"
	sudo yum -y update
}

function install-reqs {
	echo "Installing requirements..."
	sudo yum -y install wget git golang net-tools bind-utils iptables-services bridge-utils bash-completion
}

function config-docker {
	echo "Installing and configuring Docker..."
	sudo yum -y install docker
	sudo sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker
	su - root -c ' cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/sdb
VG=docker-vg
EOF'
	sudo docker-storage-setup
	sudo groupadd docker
	sudo usermod -a -G docker $(whoami)
	sg docker newgrp 'id -gn'
	sudo systemctl enable docker
	sudo systemctl start docker
}

function misc {
	echo "Disabling firewalld..."
	sudo systemctl disable firewalld.service
	sudo systemctl stop firewalld.service
	su -c 'cat hosts >> /etc/hosts'
}


function install-ose {
# Install OpenShift
  echo "Installing OpenShift..."
	curl -LO https://github.com/openshift/origin/releases/download/v3.7.0-rc.0/openshift-origin-client-tools-v3.7.0-rc.0-e92d5c5-linux-64bit.tar.gz
	tar -xvf openshift-origin-client-tools-v3.7.0-rc.0-e92d5c5-linux-64bit.tar.gz
	chmod +x openshift-origin-client-tools-v3.7.0-rc.0-e92d5c5-linux-64bit/oc
	sudo mv openshift-origin-client-tools-v3.7.0-rc.0-e92d5c5-linux-64bit/oc /usr/local/bin/oc
  oc cluster up
}

function install-kubectl {
# Install Kubectl
  echo "Installing kubectl..."
	curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	sudo mv ./kubectl /usr/local/bin/kubectl
}

function install-crunchy {
	echo "Replacing bashrc environment variables..."
	cat bashrc >> $HOME/.bashrc
	. $HOME/.bashrc

	# Get Crunchy examples
	echo "Getting the Crunchy examples..."
	cd $HOME
	git clone https://github.com/CrunchyData/crunchy-containers.git

  echo "Building the Docker images..."
	# Get Crunchy images
	export CCP_IMAGE_TAG=centos7-10.1-1.7.0
	./crunchy-containers/bin/pull-from-dockerhub.sh
}

function install-nfs {
	echo "Setting up NFS..."
	sudo setsebool -P virt_use_nfs 1
	sudo mkdir /mnt/nfsfileshare
	sudo yum -y install nfs-utils libnfsidmap
	sudo systemctl enable rpcbind
	sudo systemctl enable nfs-server
	sudo systemctl start rpcbind
	sudo systemctl start nfs-server
	sudo systemctl start rpc-statd
	sudo systemctl start nfs-idmapd
	sudo chmod 777 /mnt/nfsfileshare/
	sudo cp exports /etc
	sudo exportfs -r
	sudo mkdir /mnt/nfsfileshare
	sudo mount 10.0.2.15:/nfsfileshare /mnt/nfsfileshare
	sudo chown root:nfsnobody /mnt/nfsfileshare
}

# This needs to run after you have Openshift up and running.
# It allows the default developer user to create persistent volumes and
# perform other cluster admin functions. This is VERY permissive,
# so it is strongly discouraged to use it in production.
function configure-ose {
	echo "Configuring OpenShift permissions..."
	oc login -u system:admin
	oc adm policy add-cluster-role-to-user cluster-admin developer
}

function clone {
	echo "Cloning your environment..."
	mkdir -p $HOME/cdev/bin $HOME/cdev/src $HOME/cdev/pkg
	cd $GOPATH
	go get github.com/tools/godep
	cd src/github.com
	mkdir crunchydata
	cd crunchydata
	git clone https://github.com/crunchydata/crunchy-containers
	cd crunchy-containers
	git checkout 1.7.0
	echo "Setting up your environment..."
	make setup
	echo "Performing godep restore..."
	godep restore
}


echo "Starting VM setup..."
install-reqs
clone
install-nfs
config-docker
misc
install-crunchy
install-kubectl
install-ose
configure-ose
