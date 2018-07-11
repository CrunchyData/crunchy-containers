Crunchy Data Small Template Helm Example
=======

[PostgreSQL](https://postgresql.org) is a powerful, open source object-relational database system. It has more than 15 years of active development and a proven architecture that has earned it a strong reputation for reliability, data integrity, and correctness.


TL;DR;
------

```console
$ helm install template-small --name template-small
```

Introduction
------------

This is an example of running the Crunchy PostgreSQL containers using the Helm project! More examples of the Crunchy Containers for PostgreSQL can be found at the [GitHub repository](https://github.com/CrunchyData/crunchy-containers).

There are 3 different profiles of PostgreSQL deployment configurations - template-small, template-medium, and template-large. These templates are representative of what can be built for a typical user wanting to implement a self-service database-as-a-service.

The templates were tested on Openshift 3.7 using Gluster Container Native storage.

The template-small configuration is a simple Primary Deployment and related Service. The example specifies a storage class to be used (e.g. Gluster Container Native Storage). There are also CPU and memory limits placed in the containers.

Installing the Chart
--------------------

The chart can be installed as follows:

```console
$ helm install template-small --name template-small
```

The command deploys both the primary pods and service on the Kubernetes cluster in the default configuration.

> **Tip**: List all releases using `helm list`

Using the Chart
----------------------

You can access the primary database as follows:

```console
$ psql -h pgset-primary -U postgres postgres
```

You can access the replica databases as follows:

```console
$ psql -h pgset-replica -U postgres postgres
```

You can scale the number of containers using this command, this will
essentially create an additional replica database:

```console
$ kubectl scale template-small pgset-primary --replicas=3
```

Uninstalling the Chart
----------------------

To uninstall/delete the `template-small` deployment:

```console
$ helm del --purge template-small
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

Configuration
-------------

See `values.yaml` for configuration notes. Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install template-small --name template-small \
  --set Image.tag=centos7-9.6.9-2.0
```

The above command changes the image tag of the container from the default of `centos7-10.4-2.0` to `centos7-9.6.9-2.0`.

> **Tip**: You can use the default [values.yaml](values.yaml)

| Parameter                  | Description                        | Default                                                    |
| -----------------------    | ---------------------------------- | ---------------------------------------------------------- |
| `Name`                 | Name of release.                 | `template-small`                                        |
| `.container.port`        | The port used for the primary container      | `5432`                                                      |
| `.container.name.primary`        | Name for the primary container      | `primary`                                                      |
| `.credentials.primary`                | Password for the primary user    | `password`                                                      |
| `.credentials.root`            | Password for the root user        | `password`                                                      |
| `.credentials.user`            | Password for the standard user   | `password`                                                      |
| `.serviceType`      | The type of service      | `ClusterIP`               
| `.image.repository` | The repository on DockerHub where the images are found.    | `crunchydata`                                           |
| `.image.container` | The container to be pulled from the repository.    | `crunchy-postgres`                                                    |
| `.image.tag` | The image tag to be used.    | `centos7-10.4-2.0`                                                    |
| `.resources.cpu` | Defines a limit for CPU    | `200m`                                                    |
| `.resources.memory` | Defines a limit for memory    | `512Mi`                                                    |

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install template-small --name template-small  \
  -f values.yaml
```

Legal Notices
-------------

Copyright 2017 - 2018 Crunchy Data Solutions, Inc.

CRUNCHY DATA SOLUTIONS, INC. PROVIDES THIS GUIDE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF NON INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

Crunchy, Crunchy Data Solutions, Inc. and the Crunchy Hippo Logo are trademarks of Crunchy Data Solutions, Inc.
