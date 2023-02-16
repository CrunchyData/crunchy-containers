---
title: "crunchy-upgrade"
date:  
draft: false
---

The crunchy-upgrade container contains multiple versions of PostgreSQL in order
to perform a `pg_upgrade` between major versions of PostgreSQL. This includes
the following combinations:

- PostgreSQL 11 / PostgreSQL 12
- PostgreSQL 12 / PostgreSQL 13
- PostgreSQL 13 / PostgreSQL 14
- PostgreSQL 14 / PostgreSQL 15

## Features

The following features are supported by the crunchy-upgrade container:

 * Supports a pg_upgrade of the PostgreSQL database.
 * Doesn't alter the old database files.
 * Creates the new database directory.

## Restrictions

 * Does **not** currently support a PostGIS upgrade.
 * Supports upgrades from:
 - 11 to 12
 - 12 to 13
 - 13 to 14
 - 14 to 15

## Packages

The crunchy-upgrade Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (15.2, 14.7, 13.10, 12.14 and 11.19)
* UBI 8 - publicly available
* UBI 8 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**OLD_DATABASE_NAME**|None|Refers to the database (pod) name that we want to convert.
**NEW_DATABASE_NAME**|None|Refers to the database (pod) name that is given to the upgraded database.
**OLD_VERSION**|None|The PostgreSQL version of the old database.
**NEW_VERSION**|None|The PostgreSQL version of the new database.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PG_LOCALE**|Default locale|If set, the locale you want to create the database with.
**CHECKSUMS**|true|Enables `data-checksums` during initialization of the database.  Can only be set during initial database creation.  Set to `false` to disable data checksums.
**XLOGDIR**|None|If set, initdb will use the specified directory for WAL.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.

{{% notice tip %}}
Data checksums on the Crunchy PostgreSQL container were enabled by default in version 2.1.0.
When trying to upgrade, it's required that both the old database and the new database
have the same data checksums setting.  Prior to upgrade, check if `data_checksums`
were enabled on the database by running the following SQL: `SHOW data_checksums`
{{% /notice %}}
