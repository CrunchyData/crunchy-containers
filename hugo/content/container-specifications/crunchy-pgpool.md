---
title: "crunchy-pgpool"
date: 2018-05-24T12:05:00-07:00
draft: false
---

The crunchy-pgpool container executes the [pgPool II](http://www.pgpool.net/mediawiki/index.php/Main_Page)
utility. pgPool can be used to provide a smart PostgreSQL-aware proxy to a PostgreSQL cluster, both primary
and replica, so that applications only have to work with a single database connection.

PostgreSQL replicas are read-only whereas a primary is capable of receiving both read and write actions.

The default pgPool examples use a Secret to hold the set of pgPool configuration files used by the examples.
The Secret is mounted into the `pgconf` volume mount where the container will look to find configuration files.
If you do not specify your own configuration files via a Secret then you can specify environment
variables to the container that it will attempt to use to configure pgPool, although this is not recommended
for production environments.

## Features

The following features are supported by the `crunchy-postgres` container:

* Basic invocation of pgPool II

## Packages

The crunchy-pgpool Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5.13, 9.6.9 and 10.4)
* [pgPool II](http://www.pgpool.net/mediawiki/index.php/Main_Page)
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PG_USERNAME**|None|Username for the PostgreSQL role being used.
**PG_PASSWORD**|None|Password for the PostgreSQL role being used.
**PG_PRIMARY_SERVICE_NAME**|None|Database host to connect to for the primary node.
**PG_REPLICA_SERVICE_NAME**|None|Database host to connect to for the replica node.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
