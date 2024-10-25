<h1 align="center">Crunchy Container Suite</h1>

<p align="center">
  <img width="300" src="./images/crunchy_logo.png?raw=true"/>
</p>

## Deprecation Notice

The Crunchy Containers project is no longer actively maintained, but is made available to the extent it is
helpful as a reference to the community.  Importantly, the Crunchy Containers project is not intended for
use in connection with the latest PGO project development.

The Crunchy Containers project was released prior to the broad popularity of Kubernetes and the
[Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).  While the Crunchy
Containers project evolved over the years for use in conjunction with Kubernetes and Operators, with the
evolution and the architectural changes in PGO, the approaches taken within the Crunchy Containers project
were no longer the right solutions.

For active Crunchy Data Postgres on Kubernetes projects, please see the
[PGO repository](https://github.com/CrunchyData/postgres-operator) and the
[PGO Examples repository](https://github.com/CrunchyData/postgres-operator-examples).  To download the latest Crunchy
Postgres for Kubernetes containers, please see the [Crunchy Developer Portal](https://www.crunchydata.com/developers). 

For community support with Postgres on Kubernetes, please [join the PGO project community Discord](https://discord.com/invite/a7vWKG8Ec9). 

## General

The Crunchy Container Suite provides Docker containers that enable rapid deployment of PostgreSQL, including administration and monitoring tools. Multiple styles of deploying PostgreSQL clusters are supported.

Please view the official Crunchy Data Container Suite [documentation](https://access.crunchydata.com/documentation/crunchy-containers/):

https://access.crunchydata.com/documentation/crunchy-containers/

If you are interested in contributing, please read the [Contribution Guidelines](CONTRIBUTING.md).

## Getting Started

Complete build and install documentation is found [here](https://access.crunchydata.com/documentation/crunchy-containers/latest/installation-guide/).  The provided Dockerfiles build the containers on a Ubi 8 base image and use the community PostgreSQL RPMs.

Crunchy provides a commercially supported version of these containers built upon RHEL 7 and the Crunchy supported PostgreSQL. Contact Crunchy for more details at:

[https://www.crunchydata.com/contact/](https://www.crunchydata.com/contact/)

Further descriptions of each of these containers and environment variables that can be used to tune them can be found in the [Container Specifications](https://access.crunchydata.com/documentation/crunchy-containers/latest/container-specifications/) document.

## Usage

Various examples are provided in the [Examples](https://access.crunchydata.com/documentation/crunchy-containers/latest/examples/) documentation for running in Docker, Kubernetes, and OpenShift environments.

You will need to set up your environment as per the [Installation](https://access.crunchydata.com/documentation/crunchy-containers/latest/installation-guide/) documentation in order to execute the examples.
