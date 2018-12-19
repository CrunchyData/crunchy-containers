---
title: "crunchy-prometheus"
date: 2018-05-24T10:06:21-07:00
draft: false
weight: 8
---

[Prometheus](https://prometheus.io) is a multi-dimensional time series data model with an elastic query language. It is used in collaboration
with [Grafana](https://grafana.com/) in this metrics suite. Overall, it’s reliable, manageable, and operationally simple for efficiently
storing and analyzing data for large-scale environments. It scraps metrics from exporters such as the ones utilized by the crunchy-collect
container. The crunchy-prometheus container must be able to reach the crunchy-collect container in order to
to scrape metrics.

By default, crunchy-prometheus detects which environment its running on (Docker, Kubernetes, or OpenShift)
and applies a default configuration. If this container is running on Kubernetes or OpenShift,
it will use the Kubernetes API to discover pods with the label `"crunchy-collect": "true"`.
The crunchy-collect container must have this label defined in order to be discovered.

For Docker environments the crunchy-collect hostname must be specified as an environment
variable.

A user may define a custom `prometheus.yml` file and mount to `/conf` for custom configuration.
For configuration examples, see [here](https://github.com/crunchydata/crunchy-containers/blob/master/conf/prometheus).

The following port is exposed by the crunchy-prometheus container:

 * crunchy-prometheus:9090 - the Prometheus web user interface

## Packages

The crunchy-prometheus Docker image contains the following packages:

* [Prometheus](https://prometheus.io)
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**COLLECT_HOST**|None|Hostname of Crunchy Collect container.  Only required in **Docker** environments.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**SCRAPE_INTERVAL**|5s|Set this value to the number of seconds to scrape metrics from exporters.
**SCRAPE_TIMEOUT**|5s|Set this value to the number of seconds to timeout when scraping metrics from exporters.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
