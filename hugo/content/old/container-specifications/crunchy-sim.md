---
title: "crunchy-sim"
date: 2018-05-24T12:05:28-07:00
draft: false
---

The crunchy-sim container is a simple traffic simulator for PostgreSQL.

## Features

* Creates a single connection to PostgreSQL and will execute
queries over a specified interval range.
* Queries are specified through a simple YAML file. Each query is a name-value
  pair and can span multiple lines by utilizing scalar notation ("|" or ">") as
  defined by the YAML spec.
* Queries are randomly chosen for execution.

## Restrictions

* Only one connection is created for all queries.

## Packages

The crunchy-sim Docker image contains the following packages:

* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PGSIM_HOST**|None|The PostgreSQL host address.
**PGSIM_PORT**|None|The PostgreSQL host port.
**PGSIM_USERNAME**|None|The PostgreSQL username.
**PGSIM_PASSWORD**|None|The PostgreSQL password.
**PGSIM_DATABASE**|None|The database to connect.
**PGSIM_INTERVAL**|None|The units of the simulation interval. Valid values include: millisecond, second, and minute.
**PGSIM_MININTERVAL**|None|The minimum interval value.
**PGSIM_MAXINTERVAL**|None|The maximum interval value.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
