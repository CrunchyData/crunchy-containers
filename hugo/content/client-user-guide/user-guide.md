---
title: "User Guide"
date:
draft: false
weight: 40
---

# User Guide

## Overview

This guide is intended to get you up and running with the Crunchy Container Suite, and therefore
provides guidance for deploying the Crunchy Container Suite within your own environment.  This
includes guidance for standing-up and configuring your environment in order to run Crunchy
Containers examples that can be found in the next section.

Please see the following sections in order to properly setup and configure your environment for the
Crunchy Container Suite (_**please feel free to skip any sections that have already been completed
within your environment**_):

1. [Platform Installation](#platform-installation)
1. [Crunchy Container Suite Installation](#crunchy-container-suite-installation)
1. [Storage Configuration](#storage-configuration)
1. [Example Guidance](#example-guidance)


Once your environment has been configured according to instructions provided above, you will be
able to run the Crunchy Container Suite examples. These examples will demonstrate the various
capabilities provided by the Crunchy Container Suite, including how to properly configure and
deploy the various containers within the suite, and then utilize the features and services provided
by those containers.  The examples therefore demonstrate how the Crunchy Container Suite can be
utilized to effectively deploy a PostgreSQL database cluster within your own environment, that meets
your specific needs and contains the PostgreSQL features and services that you require.

## <a name="platform-installation"></a>Platform Installation

In order to run the examples and deploy various containers within the Crunchy Container Suite, you
will first need access to an environment containing one of the following supported platforms:

- Docker 1.13+ (https://www.docker.com/)
- Kubernetes 1.8+ (https://kubernetes.io/)
- OpenShift Container Platform 3.11 (https://www.openshift.com/products/container-platform/)

Links to the official website for each of these platform are provided above.  Please consult the
official documentation for instructions on how to install and configure these platforms in your
environment.

## <a name="crunchy-container-suite-installation"></a>Crunchy Container Suite Installation

Once you have access to an environment containing one of the supported platforms, it is then
necessary to properly configure that environment in order to run the examples, and therefore deploy
the various containers included in the Crunchy Container Suite.  This can be done by following
the Crunchy Container Suite [Installation Guide](/installation-guide/installation-guide).

Please note that as indicated within the
[Installation Guide](/installation-guide/installation-guide), certain steps may require
administrative access and/or privileges.  Therefore, please work with your local System
Administrator(s) as needed to setup and configure your environment according to the steps defined
within this guide.  Additionally, certain steps are only applicable to certain platforms and/or
environments, so please be sure to follow all instructions that are applicable to your target
environment.

## <a name="storage-configuration"></a>Storage Configuration

Once you have completed all applicable steps in the
[Installation Guide](/installation-guide/installation-guide), you can then proceed with
configuring storage in your environment.  The specific forms of storage supported by the Crunchy
Containers Suite, as well as instructions for configuring and enabling those forms of storage, can
be found in the [Storage Configuration](/installation-guide/storage-configuration) guide.
Therefore, please review and follow steps in the
[Storage Configuration](/installation-guide/storage-configuration) guide in order to properly
configure storage in your environment according to your specific storage needs.

## <a name="example-guidance"></a>Example Guidance

With the [Installation Guide](/installation-guide/installation-guide) and
[Storage Configuration](/installation-guide/storage-configuration) complete, you are almost
ready to run the examples.  However, prior to doing so it is recommended that you first review the
documentation for [Running the Examples](/client-user-guide/usage), which describes various conventions utilized in
the examples, while also providing any other information, resources and guidance relevant to
successfully running the Crunchy Container Suite examples in your environment.  The documentation
for running the examples can be found [here](/client-user-guide/usage).


