---
title: "crunchy-scheduler"
date:
draft: false
weight: 157
---

The Crunchy Scheduler container provides a cronlike microservice for automating
pgBaseBackup and pgBackRest backups within a single namespace.  The scheduler
watches Kubernetes for config maps with the label `crunchy-scheduler=true`.
If found the scheduler parses a JSON object contained in the config map and
converts it into an scheduled task.

## Packages

The Crunchy Scheduler Docker image contains the following packages:

* CentOS7 - publicly available
* RHEL7 - customers only
* Scheduler App

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**NAMESPACE**|None|The namespace the microservice should watch.  Crunchy Scheduler only works in a single namespace.
**TIMEOUT**|300|The time (in seconds) the scheduler should wait before timing out on a backup job.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.

## Permissions

Crunchy Scheduler queries Kubernetes to discover schedules and perform scheduled tasks
(either creating a job or running commands against a PostgreSQL container).  Due to the integration
with Kubernetes, Crunchy Scheduler requires a service account with the following permissions:

* Role
  * ConfigMaps: `get`, `list`, `watch`
  * Deployments: `get`, `list`, `watch`
  * Jobs: `get`, `list`, `watch`, `create, `delete`
  * Pods: `get`, `list`, `watch`
  * Pods/Exec: `create`
  * Secrets: `get`, `list`, `watch`

## Timezone

Crunchy Scheduler uses the `UTC` timezone for all schedules.

## Schedule Expression Format

Schedules are expressed using the following rules:

```
Field name   | Mandatory? | Allowed values  | Allowed special characters
----------   | ---------- | --------------  | --------------------------
Seconds      | Yes        | 0-59            | * / , -
Minutes      | Yes        | 0-59            | * / , -
Hours        | Yes        | 0-23            | * / , -
Day of month | Yes        | 1-31            | * / , - ?
Month        | Yes        | 1-12 or JAN-DEC | * / , -
Day of week  | Yes        | 0-6 or SUN-SAT  | * / , - ?
```
