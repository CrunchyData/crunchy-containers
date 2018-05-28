---
title: "crunchy-backrest-restore"
date: 2018-05-24T12:06:26-07:00
draft: false
weight: 4
---

The crunchy-backrest-restore container executes the pgBackRest utility, allowing FULL and DELTA restore capability. See the [pgBackRest](https://github.com/pgbackrest/pgbackrest) guide for more details.

## Features

The following features are supported and required by the crunchy-backrest-restore container:

 * Mounted `pgbackrest.conf` configuration file via the `/pgconf` volume
 * Mounted `/backrestrepo` for access to pgBackRest archives

## Packages

The crunchy-backrest-restore Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5.13, 9.6.9 and 10.4)
* [pgBackRest](https://pgbackrest.org/) (2.0)
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**STANZA**|None|Must be set to the desired stanza for restore.
**DELTA**|None|When set, will add the `--delta` option to the restore. The delta option allows pgBackRest to automatically determine which files in the database cluster directory can be preserved and which ones need to be restored from the backup - it also removes files not present in the backup manifest so it will dispose of divergent changes.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
