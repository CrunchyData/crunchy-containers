---
title: "crunchy-postgres"
---

## Features

The following features are supported by the `crunchy-postgres` container:

* Kubernetes and OpenShift secrets
* Backup and restoration from various tools: `pgbackrest`, `pg_basebackup` and `pg_dump`/`pg_restore`.
* Custom mounted configuration files (see below)
* Async and Sync Replication
* Configurable benchmarking options
* SQL running tool

## Packages

The crunchy-postgres Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (13.8, 12.12, 11.17, and 10.22)
* [pgBackRest](https://pgbackrest.org/) (2.31)
* pgBench (12.4, 11.9, 10.14, 9.6.19 and 9.5.23)
* rsync
* CentOS 7, UBI 8 - publicly available
* UBI 7, UBI 8 - customers only

## Running Modes

The crunchy-postgres Docker image can be run in the modes to enable functionality. The `MODE` environment variable must be set to run the image in the required mode. Each mode uses environment variables to configure how the container will be run, more information about the individual modes can be found in the following pages:

| Running Mode | `MODE` setting |
|--------------|----------------|
| [Crunchy PostgreSQL]({{< relref "/container-specifications/crunchy-postgres/postgres" >}}) | `postgres`
| [pg_basebackup job]({{< relref "/container-specifications/crunchy-postgres/backup" >}}) | `backup`
| [pg_basebackup restore job]({{< relref "/container-specifications/crunchy-postgres/pgbasebackup-restore" >}}) | `pgbasebackup-restore`
| [pg_bench job]({{< relref "/container-specifications/crunchy-postgres/pgbench" >}}) | `pgbench`
| [pg_dump job]({{< relref "/container-specifications/crunchy-postgres/pgdump" >}}) | `pgdump`
| [pg_restore job]({{< relref "/container-specifications/crunchy-postgres/pgrestore" >}}) | `pgrestore`
| [SQL runner job]({{< relref "/container-specifications/crunchy-postgres/sqlrunner" >}}) | `sqlrunner`

## Volumes

**Name**|**Description**
:-----|:-----
**/backrestrepo**|Volume used by the `pgbackrest` backup tool to store physical backups.
**/pgconf**|Volume used to store custom configuration files mounted to the container.
**/pgdata**|Volume used to store the data directory contents for the PostgreSQL database.
**/pgwal**|Volume used to store Write Ahead Log (WAL) when `XLOGDIR` environment variable is set to `true.`
**/recover**|Volume used for Point In Time Recovery (PITR) during startup of the PostgreSQL database.
