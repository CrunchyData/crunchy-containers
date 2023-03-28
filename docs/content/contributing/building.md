---
title: "Building the Containers"
date:
draft: false
weight: 250
---

# Build From Source

There are many cases where you may want to build the containers from source,
such as working on a patch to contribute a feature. This guide provides the
instructions to get you set up to build from source.

## Requirements

- Red Hat 7 environment. The instructions below are set up for
Red Hat 7, but you can read the [installation guide](/installation-guide/installation-guide)
for additional instructions
- [`go`](https://golang.org/) version 1.13+
- [`buildah`](https://buildah.io/) 1.14.9+
- [`git`](http://git-scm.org/)

## Setup

1. On your system, be sure you have installed the requirements. You can do so
with the following commands:

```shell
sudo yum -y install epel-release
sudo yum -y install golang git buildah
```

2. Create a fork of the [Crunchy Container Suite](https://github.com/CrunchyData/crunchy-containers)
repository and clone it to the environment using the following commands below:

```shell
mkdir -p $HOME/cdev/src/github.com/crunchydata $HOME/cdev/pkg $HOME/cdev/bin
cd $HOME/cdev/src/github.com/crunchydata
git clone https://github.com/crunchydata/crunchy-containers
cd crunchy-containers
```

3. Set up your local environmental variables to reference the containers you
want to build. For instance, to build the latest version, you would use the
following variables:

```shell
export GOPATH=$HOME/cdev        # set path to your new Go workspace
export GOBIN=$GOPATH/bin        # set bin path
export PATH=$PATH:$GOBIN        # add Go bin path to your overall path
export CCP_BASEOS=ubi8          # ubi8 for Red Hat Universal Base Image
export CCP_PGVERSION=15         # The PostgreSQL major version
export CCP_PG_FULLVERSION=15.2
export CCP_POSTGIS_VERSION=3.3
export CCP_VERSION=5.3.1-0
export CCP_IMAGE_PREFIX=crunchydata # Prefix to put before all the container image names
export CCP_IMAGE_TAG=$CCP_BASEOS-$CCP_PG_FULLVERSION-$CCP_VERSION   # Used to tag the images
export CCP_POSTGIS_IMAGE_TAG=$CCP_BASEOS-$CCP_PG_FULLVERSION-$CCP_POSTGIS_VERSION-$CCP_VERSION # Used to tag images that include PostGIS
export CCPROOT=$GOPATH/src/github.com/crunchydata/crunchy-containers    # The base of the clone github repo
```

You can save these variables to be set each time you open up your shell by
adding them to your `.bashrc` file:

```shell
cat >> ~/.bashrc <<-EOF
export GOPATH=$HOME/cdev
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
export CCP_BASEOS=ubi8
export CCP_PGVERSION=15
export CCP_PG_FULLVERSION=15.2
export CCP_POSTGIS_VERSION=3.3
export CCP_VERSION=5.3.1-0
export CCP_IMAGE_PREFIX=crunchydata
export CCP_IMAGE_TAG=$CCP_BASEOS-$CCP_PG_FULLVERSION-$CCP_VERSION
export CCP_POSTGIS_IMAGE_TAG=$CCP_BASEOS-$CCP_PG_FULLVERSION-$CCP_POSTGIS_VERSION-$CCP_VERSION
export CCPROOT=$GOPATH/src/github.com/crunchydata/crunchy-containers
EOF
```

4. Download the GPG Keys and repository files that are required to pull in the
packages used to build the containers:

```shell
cd $CCPROOT
curl https://api.developers.crunchydata.com/downloads/repo/rpm-centos/postgresql12/crunchypg12.repo > conf/crunchypg12.repo
curl https://api.developers.crunchydata.com/downloads/repo/rpm-centos/postgresql11/crunchypg11.repo > conf/crunchypg11.repo
curl https://api.developers.crunchydata.com/downloads/gpg/RPM-GPG-KEY-crunchydata-dev > conf/RPM-GPG-KEY-crunchydata-dev
```

5. Run the setup script to download the remaining dependencies

```shell
cd $CCPROOT
make setup
```

## Build

You can now build the containers:

```shell
cd $CCPROOT
make all
```

if you want to build an individual container such as [`crunchy-postgres`](https://www.crunchydata.com/developers/download-postgres/containers/postgresql12), you need to reference the individual name:

```shell
cd $CCPROOT
make postgres
```

To learn how to build each container, please review the Makefile targets within
the Makefile in the repository.
