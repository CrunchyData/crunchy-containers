---
title: "Primary Backup"
date: 2018-05-15T07:22:27-07:00
draft: false
---

v2.0

The Crunchy Backup template takes a `pg_basebackup` of the target database.

## Objects

The Crunchy Backup Template creates the following objects:

* Backup PVC - Volume where pg_basebackup physical backups will be stored.
* Backup Job - Short lived pod that creates a physical backup using `pg_basebackup`.

## Storage

This template assumes `STORAGE_CLASS` volumes will be used.

## Form Required

**Name**|**Description**
:-----|:-----
**VOLUME_STORAGE_CLASS**|Name of the Storage Class that provides persistence for the container.
**BACKUP_USER**|Name of the user to create the backup.  Note: this user should have replication privileges (normally `primaryuser` in Crunchy PostgreSQL).
**BACKUP_PASS**|Password of the user to create the backup.
**DB_HOSTNAME**|Service name of the PostgreSQL pod to backup.

## Multiple Backups

This templates creates a PVC automatically, however, to take multiple backups on the same volume the `BACKUP_PVC_NAME` environment field should be configured to an existing PVC.

A template error is expected when supplying an existing PVC and can be ignored.
