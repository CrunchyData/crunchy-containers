---
title: "crunchy-backup"
date: 2018-05-24T10:06:08-07:00
draft: false
weight: 3
---

The crunchy-backup container executes a full backup against another
database container using the standard pg_basebackup utility that is
included with PostgreSQL.

## Features

The following features are supported by the `crunchy-backup` container:

* Backup and restoration from: `pg_basebackup`

## Packages

The crunchy-backup Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5.13, 9.6.9 and 10.4)
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**BACKUP_LABEL**|crunchy-backup|The label for the backup.
**BACKUP_HOST**|None|Name of the database the backup is being performed on.
**BACKUP_USER**|None|Username for the PostgreSQL role being used.
**BACKUP_PASS**|None|Password for the PostgreSQL role being used.
**BACKUP_PORT**|5432|Database port used to do the backup.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.

## Volumes

**Name**|**Description**
:-----|:-----
**/backup**|Volume used by the `pg_basebackup` backup tool to store physical backups.
**/pgdata**|Volume used to store the data directory contents for the PostgreSQL database.

## Backup Location

Backups are stored in a mounted backup volume location, using the
database host name plus *-backups*  as a sub-directory, then followed by a unique
backup directory based upon a date/timestamp.  It is left to the
user to perform database backup archives in this current version
of the container. This backup location is referenced when performing
a database restore.
