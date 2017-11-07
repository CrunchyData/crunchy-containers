Crunchy Data Basic Helm Example
=======

[PostgreSQL](https://postgresql.org) is a powerful, open source object-relational database system. It has more than 15 years of active development and a proven architecture that has earned it a strong reputation for reliability, data integrity, and correctness.


TL;DR;
------

```console
$ helm install basic --name basic
```

Introduction
------------

This is an example of running the Crunchy PostgreSQL containers using the Helm project! More examples of the Crunchy Containers for PostgreSQL can be found at the [GitHub repository](https://github.com/CrunchyData/crunchy-containers).

This example will create the following in your Kubernetes cluster:

 * Create a pod named *crunchy-basic*
 * Create a service named *crunchy-basic*
 * Create a release named *crunchy-basic*
 * Initialize the database using the predefined environment variables

This example creates a simple PostgreSQL streaming replication deployment with a single primary (read-write).

Installing the Chart
--------------------

The chart can be installed as follows:

```console
$ helm install basic --name basic
```

The command deploys both primary and replica pods on the Kubernetes cluster in the default configuration.

> **Tip**: List all releases using `helm list`

Using the Chart
----------------------

After the database starts up you can connect to it as follows:

```console
$ psql -h crunchy-basic -U postgres postgres
```

Uninstalling the Chart
----------------------

To uninstall/delete the `basic` deployment:

```console
$ helm del --purge basic
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

Configuration
-------------

See `values.yaml` for configuration notes. Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install basic --name basic \
  --set Image.Tag=centos7-10.0-1.6.0
```

The above command changes the image tag of the container from the default of `centos7-9.6.5-1.6.0` to `centos7-10.0-1.6.0`.

> **Tip**: You can use the default [values.yaml](values.yaml)

| Parameter                  | Description                        | Default                                                    |
| -----------------------    | ---------------------------------- | ---------------------------------------------------------- |
| `.Name`                 | Name of release.                 | `basic`                                        |
| `.Container.Name`        | Name for the primary container      | `basic`                                                      |
| `.Credentials.Primary`                | Password for the primary user    | `password`                                                      |
| `.Credentials.Root`            | Password for the root user        | `password`                                                      |
| `.Credentials.User`            | Password for the standard user   | `password`                                                      |
| `.ServiceType`      | The type of service      | `ClusterIP`               
| `.Image.Repository` | The repository on DockerHub where the images are found.    | `crunchydata`                                           |
| `.Image.Container` | The container to be pulled from the repository.    | `crunchy-postgres`                                                    |
| `.Image.Tag` | The image tag to be used.    | `centos7-9.6.5-1.6.0`                                                    |

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install basic --name basic  \
  -f values.yaml
```

Legal Notices
-------------

Copyright © 2017 Crunchy Data Solutions, Inc.

CRUNCHY DATA SOLUTIONS, INC. PROVIDES THIS GUIDE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF NON INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

Crunchy, Crunchy Data Solutions, Inc. and the Crunchy Hippo Logo are trademarks of Crunchy Data Solutions, Inc.
