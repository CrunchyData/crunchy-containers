---
title: "crunchy-collect"
date: 2018-05-24T10:06:13-07:00
draft: false
weight: 157
---

The crunchy-collect container provides real time metrics about the PostgreSQL database
via an API. These metrics are scraped and stored by a [Prometheus](https://prometheus.io)
time-series database and are then graphed and visualized through the open source data
visualizer [Grafana](https://grafana.com/).

The crunchy-collect container uses [pgMonitor](https://github.com/CrunchyData/pgmonitor) for advanced metric collection.
It is required that the `crunchy-postgres` container has the `PGMONITOR_PASSWORD` environment
variable to create the appropriate user (`ccp_monitoring`) to collect metrics.

Custom queries to collect metrics can be specified by the user. By
mounting a **queries.yml** file to */conf* on the container, additional metrics
can be specified for the API to collect. For an example of a queries.yml file, see
[here](https://github.com/CrunchyData/pgmonitor/blob/master/exporter/postgres/queries_common.yml)

## Packages

The crunchy-collect Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (11.1, 10.6, 9.6.11 and 9.5.15)
* CentOS7 - publicly available
* RHEL7 - customers only
* [PostgreSQL Exporter](https://github.com/wrouesnel/postgres_exporter)
* [Node Exporter](https://github.com/prometheus/node_exporter)

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**DATA_SOURCE_NAME**|None|The URL for the PostgreSQL server's data source name. This is *required* to be in the form of `postgresql://`.  The user should be `ccp_monitoring` and use the `PGMONITOR_PASSWORD` value set in the `PostgreSQL` container.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**DISABLE_NODE_EXPORTER**|false|Set this to true to disable node exporter in the collect container.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
