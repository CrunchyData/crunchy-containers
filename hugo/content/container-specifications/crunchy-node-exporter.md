---
title: "crunchy-node-exporter"
date:
draft: false
weight: 13
---

[Node Exporter](https://github.com/prometheus/node_exporter) is a [Prometheus](https://prometheus.io) project used for exporing machine metrics
to the Prometheus time series database. Crunchy-Node-Exporter is a self-contained container of this project that is designed to run as a Daemonset
in Kubernetes, exporting metrics for each node it is running on. 

The following port is exposed by the crunchy-node-exporter container:

 * crunchy-node-exporter:9100 - the Prometheus web user interface



## Restrictions

It is important to provide a long enough the **SCRAPE_TIMEOUT** setting for Prometheus in the Crunchy-Prometheus container.
If it is set too low, crunchy-node-exporter may show TCP broken pipe errors in its logs. These are generally because the scrape
had not completed when Prometheus closed the scrape connection. 

## Packages

The crunchy-node-exporter Docker image contains the following packages:

* [Node Exporter](https://github.com/prometheus/node_exporter)
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.

## Permissions

Crunchy Node Exporter runs as a priviledged container and mounts the /proc and /sys as Read-only hostpath directories 
in order to obtain the metrics information from each node it is running on. Crunchy Node Exporter requires a service account 
to run properly in Red Hat Openshift.
