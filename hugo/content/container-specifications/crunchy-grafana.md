---
title: "crunchy-grafana"
date: 2018-05-24T10:06:17-07:00
draft: false
weight: 9
---

Visual dashboards are created from the collected and stored data that crunchy-collect and crunchy-prometheus
provide for the crunchy-grafana container, which hosts an open source web-based graphing dashboard called
[Grafana](https://grafana.com/).

Grafana is a platform which can then apply the defined metrics and visualize information through various tools.
It is extremely flexible with a powerful query and transformation language, producing beautiful
and easily understandable graphics to analyze and monitor your data.

By default, crunchy-grafana will register the [Prometheus](https://prometheus.io) datasource within
Grafana and import a pre-made dashboard for PostgreSQL monitoring.

The crunchy-grafana container must be able to reach the crunchy-prometheus container.

Users must specify an administrator username and password to provide basic authentication
for the web frontend. Additionally, the Prometheus hostname and port number are required. If Prometheus uses
basic authentication, users must specify the username and password to access Prometheus via environment variables.

A user may define a custom `defaults.ini` file and mount to `/conf` for custom configuration.
For configuration examples, see [here](https://github.com/crunchydata/crunchy-containers/blob/master/conf/grafana/defaults.ini).

The following port is exposed by the crunchy-grafana container:

 * crunchy-grafana:3000 - the Grafana web user interface

## Packages

The crunchy-grafana Docker image contains the following packages:

* [Grafana](https://grafana.com/)
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**ADMIN_USER**|None|Specifies the administrator user to be used when logging into the web frontend.
**ADMIN_PASS**|None|Specifies the administrator password to be used when logging into the web frontend.
**PROM_HOST**|None|Specifies the Prometheus container hostname for auto registering the Prometheus datasource.
**PROM_PORT**|None|Specifies the Prometheus container port for auto registering the Prometheus datasource.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PROM_USER**|5s|Specifies the Prometheus username, if one is required.
**PROM_PASS**|5s|Specifies the Prometheus password, if one is required.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
