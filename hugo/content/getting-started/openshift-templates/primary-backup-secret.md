---
title: "Primary Backup Secret"
date: 2018-05-15T07:22:20-07:00
draft: false
---

v2.0

The Crunchy Backup Secrets template takes a `pg_basebackup` of the target database using a pre-existing OpenShift secret to retrieve usernames and passwords for backup purposes.

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
**PG_SECRET_NAME**|Name of the secret where PostgreSQL credentials are located.
**DB_HOSTNAME**|Service name of the PostgreSQL pod to backup.

## Multiple Backups

This templates creates a PVC automatically, however, to take multiple backups on the same volume the `BACKUP_PVC_NAME` environment field should be configured to an existing PVC.

A template error is expected when supplying an existing PVC and can be ignored.
