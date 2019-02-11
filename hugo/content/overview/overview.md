---
title: "Container Images"
date:
draft: false
weight: 2
---

# Overview

The following provides a high level overview of each of the container images.

## CentOS vs RHEL Images

The Crunchy Container suite provides two different OS images: `centos7` and `rhel7`.
These images are indentical except for the packages used by `yum` to install the
software.

The `centos7` images, `yum` is configured to use PostgreSQL RPM Building Project.

The `rhel7` images use Crunchy Certified RPMs and are only available to active
Crunchy Data customers.

## Database Images

Crunchy Container Suite provides two types of PostgreSQL database images:

* Crunchy PostgreSQL
* Crunchy PostGIS

Supported major versions of these images are:

* 9.5
* 9.6
* 10
* 11

### Crunchy PostgreSQL

Crunchy PostgreSQL is an unmodified deployment of the PostgreSQL relational database.
It supports the following features:

* Asynchronous and synchronous replication
* Mounting custom configuration files such as `pg_hba.conf`, `postgresql.conf` and
  `setup.sql`
* Can be configured to use SSL authentication
* Logging to container logs
* Dedicated users for: administration, monitoring, connection pooler authentication,
  replication and user applications.
* pgBackRest backups built into the container
* Archiving WAL to dedicated volume mounts
* [Extensions available](https://www.postgresql.org/docs/current/contrib.html) in the PostgreSQL contrib module.
* Enhanced audit logging from the pgAudit extension
* Enhanced database statistics from the pg_stat_tatements extensions

### Crunchy PostgreSQL PostGIS

The Crunchy PostgreSQL PostGIS mirrors all the features of the Crunchy PostgreSQL
image but additionally provides the following geospatial extensions:

* PostGIS
* PostGIS Topology
* PostGIS Tiger Geocoder
* FuzzyStrMatch
* PLR

## Backup and Restoration Images

Crunchy Container Suite provides two types of backup images:

* Physical - backups of the files that comprise the database
* Logical - an export of the SQL that recreates the database

*Physical* backup and restoration tools included in the Crunchy Container suite are:

* [pgBackRest](2.x)
  PostgreSQL images
* [pg_basebackup](https://www.postgresql.org/docs/current/app-pgbasebackup.html) -
  provided by the Crunchy Backup image

*Logical* backup and restoration tools are:

* [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html) - provided by
  the Crunchy pgDump image
* [pg_restore](https://www.postgresql.org/docs/current/app-pgrestore.html) - provided by
  the Crunchy pgRestore image

### Crunchy Backup

The Crunchy Backup image allows users to create [pg_basebackup](https://www.postgresql.org/docs/current/app-pgbasebackup.html)
physical backups.  The backups created by Crunchy Backup can be mounted to the Crunchy
PostgreSQL container to restore databases.

### Crunchy BackRest Restore

The Crunchy BackRest Restore image restores a PostgreSQL database from pgBackRest
physical backups.  This image supports the following types of restores:

* Full - all database cluster files are restored and PostgreSQL
  replays Write Ahead Logs (WAL) to the latest point in time.  Requires an empty
  data directory.
* Delta - missing files for the database cluster are restored and PostgreSQL
  replays Write Ahead Logs (WAL) to the latest point in time.
* PITR - missing files for the database cluster are restored and PostgreSQL
  replays Write Ahead Logs (WAL) to a specific point in time.

Visit the official pgBackRest website for more information: https://pgbackrest.org/

### Crunchy pgDump

The Crunchy pgDump image creates a logical backup of the database using the
[pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html) tool.  It
supports the following features:

* `pg_dump` individual databases
* `pg_dump` all databases
* various formats of backups: plain (SQL), custom (compressed archive), directory
  (directory with one file for each table and blob being dumped with a table of
  contents) and tar (uncompressed tar archive)
* Logical backups of database sections such as: DDL, data only, indexes, schema

### Crunchy pgRestore

The Crunchy pgRestore image allows users to restore a PostgreSQL database from
`pg_dump` logical backups using the [pg_restore](https://www.postgresql.org/docs/current/app-pgrestore.html) tool.

## Administration

The following images can be used to administer and maintain Crunchy PostgreSQL
database containers.

### Crunchy pgAdmin4

The Crunchy pgAdmin4 images allows users to administer their Crunchy PostgreSQL containers
via a graphical user interface web application.

![pgadmin4](/pgadmin4.png "pgAdmin4")

Visit the official pgAdmin4 website for more information: https://www.pgadmin.org/

### Crunchy Scheduler

The Crunchy Scheduler image provides a cronlike microservice for automating
`pg_basebackup` and `pgBackRest` backups within a single Kubernetes namespace.

The scheduler watches Kubernetes for config maps with the label `crunchy-scheduler=true`.
If found the scheduler parses a JSON object contained in the config map and converts
it into an scheduled task.

### Crunchy Upgrade

The Crunchy Upgrade image allows users to perform major upgrades of their Crunchy
PostgreSQL containers.  The following upgrade versions of PostgreSQL are available:

* 9.5
* 9.6
* 10
* 11

## Performance and Monitoring

The following images can be used to understand how Crunchy PostgreSQL containers
are performing over time using tools such as Grafana, Prometheus and pgBadger.

### Crunchy Collect

The Crunchy Collect image exports metric data of Crunchy PostgreSQL containers which
can is scraped and stored by Crunchy Prometheus timeseries database via a web API.

Crunchy Collect contains the following exporters:

* [Node Exporter](https://github.com/prometheus/node_exporter) - hardware and OS metrics
* [PostgreSQL Exporter](https://github.com/wrouesnel/postgres_exporter) - postgres specific metrics

This image also contains custom PostgreSQL queries for additional metrics provided
by [Crunchy pgMonitor](https://github.com/CrunchyData/pgmonitor).

### Crunchy Grafana

The Crunchy Grafana image provides a web interface for users to explore metric data gathered and stored by
Prometheus.  Crunchy Grafana comes with the following features:

* Premade dashboards tuned for PostgreSQL metrics
* Automatic datasource registration
* Automatic administrator user setup

![grafana](/grafana.png "grafana")

Visit the official Grafana website for more information: https://grafana.com

### Crunchy Prometheus

The Crunchy Prometheus image provides a time series databases for storing metric
data gathered from Crunchy PostgreSQL containers.  Metrics can be explored via
queries in the Prometheus graphical user interface and visualized using Crunchy
Grafana.  Crunchy Prometheus supports the following features:

* Auto discovers metric exporters in Kubernetes by searching for pods with the label
  `crunchy-collect=true`
* Relabels metrics metadata for easier Crunchy Grafana integration

Visit the official Prometheus website for more information: https://prometheus.io

### Crunchy pgBadger

The Crunchy pgBadger image provides a tool that parses PostgreSQL logs and generates
an in-depth statistical report.  Crunchy pgBadger reports include:

* Connections
* Sessions
* Checkpoints
* Vacuum
* Locks
* Queries

Additionally Crunchy pgBadger can be configured to store reports for analysis over
time.

![pgbadger](/pgbadger.png "pgbadger")

Visit the official pgBadger website for more information: https://pgbadger.darold.net/

## Connection Pooling and Logical Routers

### Crunchy pgBouncer

The Crunchy pgBouncer image provides a lightweight PostgreSQL connection pooler.
Using pgBouncer, users can lower overhead of opening new connections and control
traffic to their PostgreSQL databases.  Crunchy pgBouncer supports the following
features:

* Connection pooling
* Drain, Pause, Stop connections to Crunchy PostgreSQL containers
* Dedicated pgBouncer user for authentication queries
* Dynamic user authentication

Visit the official pgBouncer website for more information: https://pgbouncer.github.io

### Crunchy pgPool II

The Crunchy pgPool image provides a logical router and connection pooler for Crunchy
PostgreSQL containers.  pgPool examines SQL queries and redirects write queries to
the primary and read queries to replicas.  This allows users to setup a single
entrypoint for their applications without requiring knowledge of read replicas.
Additionally pgPool provides connection pooling to lower overhead of opening new
connections to Crunchy PostgreSQL containers.

Visit the official pgPool II website for more information: http://www.pgpool.net
