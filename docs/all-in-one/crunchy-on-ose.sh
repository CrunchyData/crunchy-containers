#!/bin/bash
# prepare for OSE install
function setup-repos {
	sudo subscription-manager repos --disable="*"
	sudo subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-optional-rpms" \
    --enable="rhel-7-server-ose-3.3-rpms"
	sudo yum -y update
}

function install-reqs {
	sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion
	sudo yum -y install atomic-openshift-utils
}

function config-docker {
	sudo yum -y install docker-1.10.3
	sudo sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker
	su - root -c ' cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/vdb
VG=docker-vg
EOF'
	sudo docker-storage-setup
	sudo groupadd docker
	sudo usermod -a -G docker crunchy
	sudo systemctl enable docker
	sudo systemctl start docker
}

function misc {
	sudo systemctl disable firewalld.service
	sudo systemctl stop firewalld.service
	su -c 'cat hosts >> /etc/hosts'
}


function install-ose {
# install OSE as crunchy user
	# as the crunchy user set up no password ssh
	ssh-keygen
	ssh-copy-id root@crunchy
	atomic-openshift-installer install
}


function install-crunchy {
	cat bashrc >> $HOME/.bashrc
	# get crunchy examples
	cd $HOME
	git clone https://github.com/CrunchyData/crunchy-containers.git

	# get crunchy images
	export CCP_IMAGE_TAG=centos7-9.5-1.2.5
	./crunchy-containers/bin/pull-from-dockerhub.sh
}

function install-nfs {
	sudo setsebool -P virt_use_nfs 1
	sudo mkdir /nfsfileshare
	sudo yum -y install nfs-utils libnfsidmap
	sudo systemctl enable rpcbind
	sudo systemctl enable nfs-server
	sudo systemctl start rpcbind
	sudo systemctl start nfs-server
	sudo systemctl start rpc-statd
	sudo systemctl start nfs-idmapd
	sudo chmod 777 /nfsfileshare/
	sudo cp exports /etc
	sudo exportfs -r
	sudo mkdir /mnt/nfsfileshare
	sudo mount 10.0.2.15:/nfsfileshare /mnt/nfsfileshare
	sudo chown root:nfsnobody /nfsfileshare
}

# this needs to run after you have openshift up and running
# and the crunchy user account created
# this command allows the crunchy user to create PVs and other
# cluster admin functions...it is VERY wide...don't do this in production
function configure-ose {
	sudo oadm policy add-cluster-role-to-user cluster-admin crunchy
}

function clone {
	mkdir -p $HOME/cdev/bin $HOME/cdev/src $HOME/cdev/pkg
	export GOPATH=$HOME/cdev
	export CCPROOT=$GOPATH/src/github.com/crunchydata/crunchy-containers
	export CCP_IMAGE_TAG=centos7-9.6-1.2.7
	export GOBIN=$GOPATH/bin
	cd $HOME/cdev/src
	mkdir -p github.com/crunchydata
	cd github.com/crunchydata
	git clone https://github.com/CrunchyData/crunchy-containers.git
	cd crunchy-containers
	make setup
	go get github.com/tools/godep
	godep restore
}


echo "starting vm setup...."
#clone
#install-nfs
#install-reqs
#config-docker
#misc
#install-crunchy
#install-ose
#configure-ose

