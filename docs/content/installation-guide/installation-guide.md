---
title: "Installation Guide"
date:
draft: false
weight: 100
---

# Overview

This document serves four purposes:

1. Ensure you have  the prerequisites for building the images in Crunchy Container Suite
1. Make sure your local machine has all the pieces needed to run the examples in the GitHub repository
1. Run the images as standalone containers in Docker
1. Instruct you how to install the Crunchy Container Suite into Kubernetes or OpenShift

Where applicable, we will try to denote which installations and steps are required for the items above.

When we set up the directories below, you will notice they seem to be quite deeply nested. We are
setting up a [Go programming language](https://golang.org/) workspace. Go has a specific folder structure
for it's [workspaces](https://golang.org/doc/code.html#Workspaces) with multiple projects in a workspace.
If you are **not** going build the container images you can ignore the deep directories below, but it will
not hurt you if you follow the directions exactly.

# Requirements

These instructions are developed and on for the following operating systems:

- **CentOS 7**

- **RHEL 7**

We also assume you are using the Docker provided with the distributions above. If you have installed
Docker CE or EE on your machine, please create a VM for this work or uninstall Docker CE or EE.

The images in Crunchy Container Suite can run on different environments including:

- **Docker 1.13+**

- **OpenShift Container Platform 3.11**

- **Kubernetes 1.8+**

# Initial Installs

{{% notice tip %}}

Please note that _golang_ is only required if you are building the containers from source. If you do
not plan on building the containers then installing _git_ is sufficient.

{{% /notice %}}

## CentOS 7 only

    sudo yum -y install epel-release
    sudo yum -y install golang git

## RHEL 7 only

    sudo subscription-manager repos --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms"
    sudo yum -y install epel-release
    sudo yum -y install golang git

# Clone GitHub repository

Make directories to hold the GitHub clone that also work with the Go workspace structure

    mkdir -p $HOME/cdev/src/github.com/crunchydata $HOME/cdev/pkg $HOME/cdev/bin
    cd $HOME/cdev/src/github.com/crunchydata
    git clone https://github.com/crunchydata/crunchy-containers
    cd crunchy-containers
    git checkout v4.6.8

# Your Shell Environment

We have found, that because of the way Go handles different projects, you may want to create a separate account
if are plan to build the containers and work on other Go projects. You could also look into some of the
GOPATH wrappers.

If your goal is to simply run the containers, any properly configured user account should
work.

Now we need to set the project paths and software version numbers. Edit your $HOME/.bashrc file with your
favorite editor and add the following information. You can leave out the comments at the end of each
line starting with #:

    export GOPATH=$HOME/cdev        # set path to your new Go workspace
    export GOBIN=$GOPATH/bin        # set bin path
    export PATH=$PATH:$GOBIN        # add Go bin path to your overall path
    export CCP_BASEOS=ubi8       # centos7 for CentOS, ubi8 for Red Hat Universal Base Image
    export CCP_PGVERSION=13         # The PostgreSQL major version
    export CCP_PG_FULLVERSION=13.8
    export CCP_POSTGIS_VERSION=3.0  # The PostGIS version
    export CCP_VERSION=4.6.8
    export CCP_IMAGE_PREFIX=crunchydata # Prefix to put before all the container image names
    export CCP_IMAGE_TAG=$CCP_BASEOS-$CCP_PG_FULLVERSION-$CCP_VERSION   # Used to tag the images
    export CCP_POSTGIS_IMAGE_TAG=$CCP_BASEOS-$CCP_PG_FULLVERSION-$CCP_POSTGIS_VERSION-$CCP_VERSION # Used to tag images that include PostGIS
    export CCPROOT=$GOPATH/src/github.com/crunchydata/crunchy-containers    # The base of the clone github repo
    export CCP_SECURITY_CONTEXT=""
    export CCP_CLI=kubectl          # kubectl for K8s, oc for OpenShift
    export CCP_NAMESPACE=demo       # Change this to whatever namespace/openshift project name you want to use

It will be necessary to refresh your `.bashrc` file in order for the changes to take
effect.

    . ~/.bashrc

At this point we have almost all the prequesites required to build the Crunchy Container Suite.

# Building UBI Containers With Supported Crunchy Enterprise Software

Before you can build supported containers on UBI and Crunchy Supported Software, you need
to add the Crunchy repositories to your approved Yum repositories. Crunchy Enterprise Customer running on UBI
can login and download the Crunchy repository key and yum repository from <https://access.crunchydata.com/>
on the downloads page. Once the files are downloaded please place them into the `$CCPROOT/conf` directory (defined
above in the environment variable section).

## Install Docker

{{% notice info %}}

The OpenShift and Kubernetes (KubeAdm) instructions both have a section for installing docker. Installing
docker now won't cause any issues but you may wish to configure Docker storage before bringing
everything up. Configuring Docker Storage is different from _Storage Configuration_ referenced later in the
instructions and is not covered here.

For a basic docker installation, you can follow the instructions below. Please refer to
the respective installation guide for the version of Kubernetes you are installing for
more specific details.

{{% /notice %}}

Install Docker

    sudo yum -y install docker

It is necessary to add the `docker` group and give your user access
to that group:

    sudo groupadd docker
    sudo usermod -a -G docker <username>

Logout and login again as the same user to allow group settings to take effect.

Enable Docker service and start Docker (once all configuration is complete):

    sudo systemctl enable docker.service
    sudo systemctl start docker.service

{{% notice info %}}

At this point you should be able to build the containers. Please to go to [Building the Containers](/contributing/building/)
page and continue from there.

{{% / notice %}}

## Install PostgreSQL

{{% notice tip %}}

You only need to install PostgreSQL locally if you want to use the examples - it is not required for
either building the containers or installing the containers into Kubernetes.

{{% / notice %}}

There are a variety of ways you can [download PostgreSQL](https://www.crunchydata.com/developers/download-postgres).

For specific installation instructions for [installing PostgreSQL 12 on CentOS](https://www.crunchydata.com/developers/download-postgres/binaries/postgresql12), please visit the [Crunchy Data Developer Portal](https://www.crunchydata.com/developers):

[https://www.crunchydata.com/developers/download-postgres/binaries/postgresql12](https://www.crunchydata.com/developers/download-postgres/binaries/postgresql12)

## Configuring Storage for Kubernetes Based Systems

In addition to the environment variables we set earlier, you will need to add environment variables
for Kubernetes storage configuration. Please see the [Storage Configuration](/installation-guide/storage-configuration/)
document for configuring storage using environment variables set in `.bashrc`.

Don't forget to:

    source ~/.bashrc

## OpenShift Installation

Use the OpenShift installation guide to install OpenShift Enterprise on your host. Make sure
to choose the proper version of OpenShift you want to install. The main instructions for
3.11 are here and you'll be able to select a different version there, if needed:

<https://docs.openshift.com/container-platform/3.11/install/index.html>

## Kubernetes Installation

{{% notice warning %}}
Make sure your hostname resolves to a single IP address in your
/etc/hosts file. The NFS examples will not work otherwise and other problems
with installation can occur unless you have a resolving hostname.

You should see a single IP address returned from this command:

    hostname --ip-address

{{% /notice %}}

### Installing Kubernetes

We suggest using Kubeadm as a simple way to install Kubernetes.

See [Kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/)
for installing the latest version of Kubeadm.

See [Create a Cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
for creating the Kubernetes cluster using **Kubeadm**. Note: We find that Weave networking
works particularly well with the container suite.

Please see [here](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
to view the official documentation regarding configuring DNS for your Kubernetes cluster.

### Post Kubernetes Configuration

In order to run the various examples, Role Based Account Control will need to be set up.
Specifically, the **cluster-admin** role will need to be assigned to the Kubernetes user
that will be utilized to run the examples. This is done by creating the proper
**ClusterRoleBinding**:

    $ kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin --user someuser

If you are running on GKE, the following command can be utilized to auto-populate the **user**
option with the account that is currently logged into Google Cloud:

    $ kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin --user $(gcloud config get-value account)

If more than one user will be running the examples on the same Kubernetes cluster, a unique name
will need to be provided for each new **ClusterRoleBinding** created in order to assign the
**cluster-admin** role to every user. The example below will create a **ClusterRoleBinding** with a
unique value:

    $ kubectl create clusterrolebinding <unique>-cluster-admin-binding \
        --clusterrole cluster-admin \
        --user someuser

If you are running on GKE, the following can be utilized to create a unique **ClusterRoleBinding**
for each user, with the user’s Google Cloud account prepended to the name of each new
**ClusterRoleBinding**:

    $ kubectl create clusterrolebinding "$(gcloud config get-value account)-cluster-admin-binding" \
        --clusterrole cluster-admin \
        --user $(gcloud config get-value account)

## Helm

Some Kubernetes Helm examples are provided in the following directory as one
option for deploying the Container Suite.

    $CCPROOT/examples/helm/

Once you have your Kubernetes environment configured, it is simple to get
Helm up and running. Please refer to [this document](https://github.com/kubernetes/helm/blob/master/docs/install.md)
to get Helm installed and configured properly.

# Configuring Namespace and Permissions

In Kubernetes, a concept called a **namespace** provides the means to separate
created resources or components into individual logically grouped partitions. In OpenShift,
_namespace_ is referred to as a _project_.

It is considered a best practice to have dedicated namespaces for projects in
both testing and production environments.

{{% notice info %}}
All examples in the Crunchy Container Suite operate within the namespace
defined by the environment variable `$CCP_NAMESPACE`. The default we use for namespace
is 'demo' but it can be set to any valid namespace name. The instructions below
illustrate how to set up and work within new namespaces or projects in both
Kubernetes and OpenShift.
{{% /notice %}}

## Kubernetes

This section will illustrate how to set up a new Kubernetes namespace called **demo**, and will
then show how to provide permissions to that namespace to allow the Kubernetes examples to run
within that namespace.

First, view currently existing namespaces:

    $ kubectl get namespace
    NAME          STATUS    AGE
    default       Active    21d
    kube-public   Active    21d
    kube-system   Active    21d

Then, create a new namespace called **demo**:

    $ kubectl create -f $CCPROOT/conf/demo-namespace.json
    namespace "demo" created
    $ kubectl get namespace demo
    NAME      STATUS    AGE
    demo      Active    7s

Then set the namespace as the default for the current context:

{{% notice tip %}}

When a namespace is not explicitly stated for a command, Kubernetes uses the namespace
specified by the currently set context.

{{% /notice %}}

    kubectl config set-context $(kubectl config current-context) --namespace=demo

We can verify that the namespace was set correctly through the following command:

    $ kubectl config view | grep namespace:
        namespace: demo

## OpenShift

This section assumes an administrator has already logged in first as the **system:admin** user
as directed by the OpenShift Installation Guide.

For our development purposes only, we typically specify the OCP
Authorization policy of `AllowAll` as documented here:

<https://docs.openshift.com/container-platform/3.11/install_config/configuring_authentication.html#AllowAllPasswordIdentityProvider>

We do not recommend this authentication policy for a production
deployment of OCP.

{{% notice tip %}}
For the best results, it is recommended that you run the examples with a user that has **NOT** been
assigned the **cluster-admin** cluster role.
{{% /notice %}}

Log into the system as a user:

    oc login -u <user>

The next step is to create a **demo** namespace to run the examples within. The
name of this OCP project will be what you supply in the CCP\_NAMESPACE
environment variable:

    $ oc new-project demo --description="Crunchy Containers project" --display-name="Crunchy-Containers"
    Now using project "demo" on server "https://127.0.0.1:8443".

    $ export CCP_NAMESPACE=demo

If we view the list of projects, we can see the new project has been added and is "active".

    $ oc get projects
    NAME        DISPLAY NAME         STATUS
    demo        Crunchy-Containers   Active
    myproject   My Project           Active

If you were on a different project and wanted to switch to the demo project, you would do
so by running the following:

    $ oc project demo
    Now using project "demo" on server "https://127.0.0.1:8443".

When self-provisioning a new project using the `oc new-project` command, the current user (i.e.,
the user you used when logging into OCP with the `oc login` command) will automatically be assigned
to the **admin** role for that project. This will allow the user to create the majority of the
objects needed to successfully run the examples. However, in order to create the **Persistent
Volume** objects needed to properly configure storage for the examples, an additional role is
needed. Specifically, a new role is needed that can both create and delete **Persistent Volumes**.

Using the following two commands, create a new Cluster Role that has the ability to create and delete
persistent volumes, and then assign that role to your current user:

{{% notice warning %}}
Please be aware that the following two commands require privileges that your current user may not
have. In the event that you are unable to run these commands, and do not have access to a user
that is able to run them (e.g., the **system:admin** user that is created by default when
installing OCP), please contact your local OCP administrator to run the commands on your behalf, or
grant you the access required to run them yourself.
{{% /notice %}}

    $ oc create clusterrole crunchytester --verb="list,create,delete" --resource=persistentvolumes
    clusterrole "crunchytester" created

    $ oc adm policy add-cluster-role-to-user crunchytester someuser
    cluster role "crunchytester" added: "someuser"

Your user should now have the roles and privileges required to run the examples.
