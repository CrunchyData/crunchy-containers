---
title: "pgAdmin 4"
date:
draft: false
weight: 81
---

## pgAdmin4 example
This example deploys the pgadmin4 v2 web user interface
for PostgreSQL without TLS.

After running the example, you should be able to browse to http://127.0.0.1:5050
and log into the web application with the following configured credentials:

 * Username : *admin@admin.com*
 * Password: *password*

If you are running this example using Kubernetes or
OpenShift, it is required to use a port-forward proxy to access the dashboard.

To start the port-forward proxy run the following:

```
${CCP_CLI} port-forward pgadmin4-http 5050:5050
```

To access the pgAdmin4 dashboard through the proxy, navigate to *http://127.0.0.1:5050*
in a browser.

See the [pgAdmin4 documentation](http://pgadmin.org) for more details.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

## Docker

To run this example, run the following:
```
cd $CCPROOT/examples/docker/pgadmin4-http
./run.sh
```

## Kubernetes and OpenShift

Start the container as follows:
```
cd $CCPROOT/examples/kube/pgadmin4-http
./run.sh
```

{{% notice tip %}}
An emptyDir with write access must be mounted to the `/run/httpd` directory in OpenShift.
{{% /notice %}}

# pgAdmin4 with TLS

This example deploys the pgadmin4 v2 web user interface
for PostgreSQL with TLS.

After running the example, you should be able to browse to https://127.0.0.1:5050
and log into the web application with the following configured credentials:

 * Username : *admin@admin.com*
 * Password: *password*

If you are running this example using Kubernetes or
OpenShift, it is required to use a port-forward proxy to access the dashboard.

To start the port-forward proxy run the following:

```
${CCP_CLI} port-forward pgadmin4-https 5050:5050
```

To access the pgAdmin4 dashboard through the proxy, navigate to *https://127.0.0.1:5050*
in a browser.

See the [pgadmin4 documentation](http://pgadmin.org) for more details.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

## Docker

To run this example, run the following:
```
cd $CCPROOT/examples/docker/pgadmin4-https
./run.sh
```

## Kubernetes and OpenShift

Start the container as follows:
```
cd $CCPROOT/examples/kube/pgadmin4-https
./run.sh
```

{{% notice tip %}}
An emptyDir with write access must be mounted to the `/run/httpd` directory in OpenShift.
{{% /notice %}}
