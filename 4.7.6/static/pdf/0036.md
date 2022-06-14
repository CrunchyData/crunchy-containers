---
title: "crunchy-postgres-gis"
date:
draft: false
---

PostgreSQL (pronounced "post-gress-Q-L") is an open source, ACID compliant, 
relational database management system (RDBMS) developed by a worldwide team of volunteers. 
The crunchy-postgres-gis container image is unmodified, open source PostgreSQL packaged and maintained by professionals. 
This image is identical to the crunchy-postgres image except it includes the open source geospatial extension [PostGIS](https://postgis.net/) for PostgreSQL.

For more information about configuration options for the `crunchy-postgres-gis` 
please reference the [`crunchy-postgres`]({{< relref "/container-specifications/crunchy-postgres" >}}) documentation. 
The `crunchy-postgres-gis` image is built using the `crunchy-postgres` image and 
supports the same features, packages, running modes, and volumes.

## Features

In addition to features provided by the `crunchy-postgres` container, the following features are supported by the `crunchy-postgres-gis` container:

* PostGIS

## Running Modes

The `crunchy-postgres-gis` Docker image can be run in modes to enable functionality. 
The `MODE` environment variable must be set to run the image in the correct mode. 
Each mode uses environment variables to configure how the container will be run. 
More information about these environment variables and custom configurations for each mode can be found in the following pages:

* [Crunchy PostgreSQL]({{< relref "/container-specifications/crunchy-postgres" >}}): `postgres`
* [Crunchy backup]({{< relref "/container-specifications/crunchy-postgres" >}}): `backup`
* [Crunchy pgbasebackup restore]({{< relref "/container-specifications/crunchy-postgres" >}}-restore): `pgbasebackup-restore`
* [Crunchy pgbench]({{< relref "/container-specifications/crunchy-postgres" >}}): `pgbench`
* [Crunchy pgdump]({{< relref "/container-specifications/crunchy-postgres" >}}): `pgdump`
* [Crunchy pgrestore]({{< relref "/container-specifications/crunchy-postgres" >}}): `pgrestore`
* [Crunchy sqlrunner]({{< relref "/container-specifications/crunchy-postgres/sqlrunner" >}}): `sqlrunner`

