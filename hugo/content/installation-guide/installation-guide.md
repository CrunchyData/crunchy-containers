---
title: "Installation Guide"
date:
draft: false
weight: 100
---

# Requirements

These installation instructions are developed and tested for the following operating systems:

  - **CentOS 7**

  - **RHEL 7**

The Crunchy Container Suite can run on different environments including:

  - **Docker 1.13+**

  - **OpenShift Container Platform 3.11**

  - **Kubernetes 1.8+**

In this document we list the basic installation steps required for these
environments.


# Project Environment

If your goal is to simply run the containers any properly configured user account should
work. If your goal is for development and/or building the containers, we recommend a user
whose environment is dedicated for that purpose.

First add the following lines to your .bashrc file to set the project paths:

    export GOPATH=$HOME/cdev
    export GOBIN=$GOPATH/bin
    export PATH=$PATH:$GOBIN
    export CCP_BASEOS=centos7       # centos7 for Centos, rhel7 for Redhat
    export CCP_PGVERSION=10
    export CCP_PG_FULLVERSION=10.7
    export CCP_VERSION=2.3.1
    export CCP_IMAGE_PREFIX=crunchydata
    export CCP_IMAGE_TAG=$CCP_BASEOS-$CCP_PG_FULLVERSION-$CCP_VERSION
    export CCPROOT=$GOPATH/src/github.com/crunchydata/crunchy-containers
    export CCP_SECURITY_CONTEXT=""
    export CCP_CLI=kubectl          # kubectl for K8s, oc for OpenShift
    export CCP_NAMESPACE=demo

{{% notice tip %}}

You will need to add environment variables for storage configuration as well. Please see
the [Storage Configuration](/installation/storage-configuration/) document
for configuring storage using environment variables set in `.bashrc`.

{{% /notice %}}

It will be necessary to refresh your `.bashrc` file in order for the changes to take
effect.

    . ~/.bashrc

Next, set up a project directory structure and pull down the project from github:

    mkdir -p $HOME/cdev/src/github.com/crunchydata $HOME/cdev/pkg $HOME/cdev/bin

# Installation

{{% notice tip %}}

The installation for Centos 7 and RHEL 7 are similar, but there are several steps which
require slightly different commands related to location of repositories, etc. These are
highlighted below where necessary.

{{% /notice %}}

## Install Supporting Software

### CentOS 7 only

    sudo yum -y install epel-release --enablerepo=extras
    sudo yum -y install golang git

### RHEL 7 only

    sudo subscription-manager repos --enable=rhel-7-server-optional-rpms
    sudo yum-config-manager --enable rhel-7-server-extras-rpms
    sudo yum -y install git golang


## Clone GitHub repository

    cd $GOPATH/src/github.com/crunchydata
    git clone https://github.com/crunchydata/crunchy-containers
    cd crunchy-containers
    git checkout 2.3.1
    go get github.com/blang/expenv

{{% notice info %}}

If you are a Crunchy Enterprise Customer running on RHEL, you will place the Crunchy repository
key and yum repository file into the `$CCPROOT/conf` directory at this point. These
files can be obtained through <https://access.crunchydata.com/> on the downloads
page.

{{% /notice %}}


## Install PostgreSQL

These installation instructions assume the installation of PostgreSQL 10
through the official PGDG repository. View the documentation located
[here](https://wiki.postgresql.org/wiki/YUM_Installation) in
order to view more detailed notes or install a different version of PostgreSQL.

Locate and edit your distribution’s `.repo` file, located:

  - On **CentOS**: /etc/yum.repos.d/CentOS-Base.repo, \[base\] and \[updates\] sections

  - On **RHEL**: /etc/yum/pluginconf.d/rhnplugin.conf \[main\] section

To the section(s) identified above, depending on OS being used, you need to append a line to prevent dependencies
 from getting resolved to the PostgreSQL supplied by the base repository:

    exclude=postgresql*

Next, install the RPM relating to the base operating system and PostgreSQL version
you wish to install. The RPMs can be found [here](https://yum.postgresql.org/repopackages.php).
Below we chose Postgresql 10 for the example (change if you need different version):

On **CentOS** system:

    sudo yum -y install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm

On  **RHEL** system:

    sudo yum -y install https://download.postgresql.org/pub/repos/yum/testing/10/redhat/rhel-7-x86_64/pgdg-redhat10-10-2.noarch.rpm

Update the system:

    sudo yum -y update

Install the PostgreSQL server package.

    sudo yum -y install postgresql10-server.x86_64

Update the system:

    sudo yum -y update


## Install Docker

{{% notice info %}}

The OpenShift and Kubernetes (KubeAdm) instructions both have a section for installing docker. Installing
docker now won't cause any issues but you may wish to configure Docker storage before bringing
everything up. Configuring Docker Storage is different from *Storage Configuration* referenced earlier in the
instructions and is not covered here.

For a basic docker installation, you can follow the instructions below. Please refer to
the respective installation guide for the version of Kubernetes you are installing for
more specific details.


{{% /notice %}}

    sudo yum -y install docker

It is necessary to add the `docker` group and give your user access
to that group:

    sudo groupadd docker
    sudo usermod -a -G docker <username>

Logout and login again as the same user to allow group settings to take effect.

Enable Docker service and start Docker (once all configuration is complete):

    sudo systemctl enable docker.service
    sudo systemctl start docker.service

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

    $ hostname --ip-address

{{% /notice %}}

### Installing Kubernetes

We suggest using Kubeadm as a simple way to install Kubernetes.

See [Kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/)
for installing the latest version of Kubeadm.

See [Create a Cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
for creating the Kuberenetes cluster using **Kubeadm**. Note: We find that Weave networking
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
*namespace* is referred to as a *project*.

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


    $ kubectl config set-context $(kubectl config current-context) --namespace=demo

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

    $ oc login -u <user>


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
