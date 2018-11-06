---
title: "crunchy-scheduler"
date: 2018-05-24T10:06:13-07:00
draft: false
weight: 7
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
