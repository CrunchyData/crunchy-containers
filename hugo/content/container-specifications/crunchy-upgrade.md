---
title: "crunchy-upgrade"
date: 2018-05-24T12:05:31-07:00
draft: false
---

The crunchy-upgrade container contains both the 9.5/9.6 and 9.6/10
PostgreSQL packages in order to perform a pg_upgrade from
9.5 to 9.6 or 9.6 to 10 versions.

## Features

The following features are supported by the crunchy-upgrade container:

 * Supports a pg_upgrade of the PostgreSQL database.
 * Doesn't alter the old database files.
 * Creates the new database directory.

## Restrictions

 * Does **not** currently support a PostGIS upgrade.
 * Supports upgrades from only 9.5 to 9.6, or 9.6 to 10.

## Packages

The crunchy-upgrade Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5.13, 9.6.9 and 10.4)
* CentOS7 - publicly available
* RHEL7 - customers only

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
**CHECKSUMS**|Disabled|If set, this value is used to enable the `--data-checksums` option when initdb is executed at initialization.
**XLOGDIR**|None|If set, initdb will use the specified directory for WAL.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
