# !/bin/bash
# Installation script to set up a test environment in a more automated fashion.
#
# Replace variables here!
cat <<EOF >> ~/.bashrc
export GOPATH=$HOME/cdev
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
export CCP_BASEOS=centos7
export CCP_PGVERSION=9.6
export CCP_VERSION=1.5
export CCP_IMAGE_TAG=$CCP_BASEOS-$CCP_PGVERSION-$CCP_VERSION
export CCPROOT=$GOPATH/src/github.com/crunchydata/crunchy-containers
EOF

source ~/.bashrc

mkdir -p $HOME/cdev $HOME/cdev/src $HOME/cdev/pkg $HOME/cdev/bin
cd $GOPATH
sudo yum -y install golang git docker postgresql
go get github.com/tools/godep
cd src/github.com
mkdir crunchydata
cd crunchydata
git clone https://github.com/crunchydata/crunchy-containers
cd crunchy-containers

# Replace variable here with current container version!

git checkout 1.5
godep restore

sudo yum -y update
sudo groupadd docker
sudo usermod -a -G docker "${USER}"

cd $CCPROOT
make setup
make all

printf "Now time to create Docker storage hard disk...\n"
printf "(1) Add new hard disk via VirtualBox.\n"
printf "(2) Run this command to format the drive, where /dev/sd? is the new hard drive that was added:\n fdisk /dev/sd?\n\n"
printf "Next, create a volume group on the new drive partition within the fdisk utility:\n vgcreate docker-vg /dev/sd?\n\n"
printf "Then, you’ll need to edit the docker-storage-setup configuration file in order to override default options. Add these two lines to /etc/sysconfig/docker-storage-setup:\n DEVS=/dev/sd?\n VG=docker-vg\n\n"
printf "Finally, run the command docker-storage-setup to use that new volume group. The results should state that the physical volume /dev/sd? and the volume group docker-vg have both been successfully created."
printf "Next, we enable and start up Docker:\n sudo systemctl enable docker.service\nsudo systemctl start docker.service\n\n"
printf "After that, run setup-env-2.sh."
