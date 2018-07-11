---
title: "pgAdmin4"
date: 2018-05-15T07:22:02-07:00
draft: false
---

v2.0

Crunchy pgAdmin4 Template provides a feature rich, GUI Open Source administration and development platform for PostgreSQL.

## Objects

The Crunchy pgAdmin4 Template creates the following objects:

* pgAdmin4 Secret - email and password for login
* pgAdmin4 PVC - Volume where pgAdmin4 data will be stored
* pgAdmin4 Service - Service connected to the pgAdmin4 pod
* pgAdmin4 Pod - pgAdmin4 web application

## Storage

This template assumes `STORAGE_CLASS` volumes will be used.

## Form Required
**Name**|**Description**
:-----|:-----
**VOLUME_STORAGE_CLASS**|Name of the Storage Class that provides persistence for the container.
**PGADMIN_EMAIL**|Email address used to login to the web application.
**PGADMIN_PASSWORD**|Password used to login to the web application.
