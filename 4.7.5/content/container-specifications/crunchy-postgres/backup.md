---
title: "backup"
---

The backup running mode executes a full backup against another
database container using the standard pg_basebackup utility that is
included with PostgreSQL.

MODE: `backup`

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**MODE**|None|Set to `backup` to run as `pg_basebackup` job
**BACKUP_LABEL**|crunchy-backup|The label for the backup.
**BACKUP_HOST**|None|Name of the database the backup is being performed on.
**BACKUP_USER**|None|Username for the PostgreSQL role being used.
**BACKUP_PASS**|None|Password for the PostgreSQL role being used.
**BACKUP_PORT**|5432|Database port used to do the backup.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
**BACKUP_OPTS**|None|Optional parameters to pass to pg_basebackup.

## Backup Location

Backups are stored in a mounted backup volume location, using the
database host name plus *-backups*  as a sub-directory, then followed by a unique
backup directory based upon a date/timestamp.  It is left to the
user to perform database backup archives in this current version
of the container. This backup location is referenced when performing
a database restore.
