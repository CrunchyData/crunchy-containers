---
title: "Primary Replica"
date: 2018-05-15T07:22:10-07:00
draft: false
---

v2.0

The Crunchy PostgreSQL Primary/Replica Template creates a primary pod with replica statefulsets to provide a database cluster with streaming replication.

## Objects

The Crunchy PostreSQL Primary/Replica Template creates the following objects:

* PostgreSQL Secret - usernames and passwords generated from the template
* PGData PVC - Volume where PostgreSQL database will be stored
* Backup PVC - Volume where pg_basebackup physical backups will be stored
* Backrestrepo PVC - Volume where pgBackRest physical backups will be stored
* Primary Service - Service connected to the Primary Pod
* Replica Service - Service connected to the Replica Pods
* Primary Pod - Primary database pod
* Replica Statefulset - Replica database pods

## Storage

This template assumes `STORAGE_CLASS` volumes will be used.

## Form Required
**Name**|**Description**
:-----|:-----
**VOLUME_STORAGE_CLASS**|Name of the Storage Class that provides persistence for the container.
