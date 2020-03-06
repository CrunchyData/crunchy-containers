---
title: "crunchy-collect"
date: 2018-05-24T10:06:13-07:00
draft: false
weight: 3
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

* PostgreSQL (12.2, 11.7, 10.12, 9.6.17 and 9.5.21)
* CentOS7 - publicly available
* UBI7 - customers only
* [PostgreSQL Exporter](https://github.com/wrouesnel/postgres_exporter)

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**COLLECT_PG_PASSWORD**|none|Provides the password needed to generate the PostgreSQL URL required by the PostgreSQL Exporter to connect to a PG database.  Should typically match the `PGMONITOR_PASSWORD` value set in the `crunchy-postgres` container.|

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**COLLECT_PG_USER**|ccp_monitoring|Provides the username needed to generate the PostgreSQL URL required by the PostgreSQL Exporter to connect to a PG database.  Should typically be `ccp_monitoring` per the [crunchy-postgres](/container-specifications/crunchy-postgres) container specification (see environment varaible `PGMONITOR_PASSWORD`).
**COLLECT_PG_HOST**|127.0.0.1|Provides the host needed to generate the PostgreSQL URL required by the PostgreSQL Exporter to connect to a PG database|
**COLLECT_PG_PORT**|5432|Provides the port needed to generate the PostgreSQL URL required by the PostgreSQL Exporter to connect to a PG database|
**COLLECT_PG_DATABASE**|postgres|Provides the name of the database used to generate the PostgreSQL URL required by the PostgreSQL Exporter to connect to a PG database|
**DATA_SOURCE_NAME**|None|Explicitly defines the URL for connecting to the PostgreSQL database (must be in the form of `postgresql://`).  If provided, overrides all other settings provided to generate the connection URL.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
**POSTGRES_EXPORTER_PORT**|9187|Set the postgres-exporter port to listen on for web interface and telemetry.

## Volumes

**Name**|**Description**
:-----|:-----
**/collect-pguser**|Volume containing PG credentials stored in `username` and `password` files (e.g. mounted using a Kubernetes secret)
