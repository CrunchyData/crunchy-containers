
---
title: "Metrics and Performance"
date:
draft: false
weight: 61
---

## Metrics Collection

You can collect various PostgreSQL metrics from your database
container by running a crunchy-collect container that points
to your database container.

This example starts up 5 containers:

 * Collect (crunchy-collect)
 * Grafana (crunchy-grafana)
 * PostgreSQL (crunchy-postgres)
 * Prometheus (crunchy-prometheus)

Every 5 seconds by default, Prometheus will scrape the Collect container
for metrics.  These metrics will then be visualized by Grafana, which by default can be accessed
with the following credentials:

* Username : *admin*
* Password: *password*

By default, Prometheus detects which environment its running on (Docker, Kubernetes, or OpenShift Container Platform)
and applies a default configuration.

When running in Kuberenetes and OpenShift, the following two labels are required by
the deployments:

 * `"crunchy_collect": "true"`
 * `"name": "some-pod-name-here"`

The `crunchy_collect` label allows Prometheus to find all pods that are serving metrics
to be scraped for storage.

The `name` label allows Prometheus to rewrite the name of the pod so if it changes there's not
duplicate entries.

Additionally, the collect container uses a special PostgreSQL role `ccp_monitoring`.
This user is created by setting the `PGMONITOR_PASSWORD` environment variable on the
PostgreSQL container.

Discovering pods requires a cluster role service account.  See the
[Kubernetes and OpenShift](https://github.com/crunchydata/crunchy-containers/blob/master/examples/kube/metrics/metrics.json)
metrics JSON file for more details.

For Docker environments the collect hostname must be specified as an environment
variable.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

To delete the cluster role required by the Prometheus, as an administrator, run the following:

```
./cleanup-rbac.sh
```

### Docker

To start this set of containers, run the following:
```
cd $CCPROOT/examples/docker/metrics
./run.sh
```

You will be able to access the Grafana and Prometheus services from the following
web addresses:

 * Grafana (http://0.0.0.0:3000)
 * Prometheus (http://0.0.0.0:9090)

The crunchy-postgres container is accessible on port *5432*.

### Kubernetes and OpenShift

Running the example:
```
cd $CCPROOT/examples/kube/metrics
./run.sh
```

It's required to use `port-forward` to access the Grafana dashboard.  To start the
port-forward, run the following command:

```
${CCP_CLI} port-forward metrics 3000:3000
${CCP_CLI} port-forward metrics 9090:9090
```

 * Grafana dashboard can be then accessed from `http://127.0.0.01:3000`
 * Prometheus dashboard can be then accessed from `http://127.0.0.01:9090`

You can view the container logs using these command:
```
${CCP_CLI} logs -c grafana metrics
${CCP_CLI} logs -c prometheus metrics
${CCP_CLI} logs -c collect primary-metrics
${CCP_CLI} logs -c postgres primary-metrics
${CCP_CLI} logs -c collect replica-metrics
${CCP_CLI} logs -c postgres replica-metrics
```
