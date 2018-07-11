---
title: "Primary Restore Secret"
date: 2018-05-15T07:22:45-07:00
draft: false
---

v2.0

The Crunchy PostgreSQL Primary Restore Template creates a single primary pod from a `pg_basebackup` physical backup.

## Objects

The Crunchy PostreSQL Primary Template creates the following objects:

* PGData PVC - Volume where PostgreSQL database will be stored
* Primary Service - Service connected to the Primary Pod
* Primary Pod - Primary database pod

## Storage

This template assumes `STORAGE_CLASS` volumes will be used.

The template assumes a **BACKUP PVC** has been created and contains a backup.

## Form Required
**Name**|**Description**
:-----|:-----
**VOLUME_STORAGE_CLASS**|Name of the Storage Class that provides persistence for the container.
**BACKUP_PVC_NAME**|Name of the PVC where the physical backups are stored.
**BACKUP_DATE**|Timestamp of the backup to use from the Crunchy Backup job.
**BACKUP_HOSTNAME**|Hostname of the backed up database.
**PG_SECRET_NAME**|Name of the secret of the backed up database (can be retrieved from `secrets`).
