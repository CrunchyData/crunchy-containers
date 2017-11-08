Crunchy Data Primary / Replica Helm Example
=======

[PostgreSQL](https://postgresql.org) is a powerful, open source object-relational database system. It has more than 15 years of active development and a proven architecture that has earned it a strong reputation for reliability, data integrity, and correctness.


TL;DR;
------

```console
$ helm install primary-replica --name primary-replica
```

Introduction
------------

This is an example of running the Crunchy PostgreSQL containers using the Helm project! More examples of the Crunchy Containers for PostgreSQL can be found at the [GitHub repository](https://github.com/CrunchyData/crunchy-containers).

This example will create the following in your Kubernetes cluster:

 * Create a service named *primary*
 * Create a service named *replica*
 * Create a pod named *primary*
 * Create a deployment named *replica*
 * Create a persistent volume named *primary-pv* and a persistent volume claim of *primary-pvc*
 * Initialize the database using the predefined environment variables

This example creates a simple PostgreSQL streaming replication deployment with a primary (read-write), and a single asynchronous replica (read-only). You can scale up the number of replicas dynamically.

Installing the Chart
--------------------

The chart can be installed as follows:

```console
$ helm install primary-replica --name primary-replica
```

The command deploys both primary and replica pods on the Kubernetes cluster in the default configuration.

> **Tip**: List all releases using `helm list`

Using the Chart
----------------------

After installing the Helm chart, you will see the following services:
```console
$ kubectl get services
NAME                          TYPE        CLUSTER-IP   EXTERNAL-IP      PORT(S)    AGE
primary   ClusterIP   10.0.0.99    <none>           5432/TCP   22m
replica   ClusterIP   10.0.0.253   <none>           5432/TCP   22m
kubernetes                    ClusterIP   10.0.0.1     <none>           443/TCP    7h
```

It takes about a minute for the replica to begin replicating with the
primary.  To test out replication, see if replication is underway
with this command, enter *password* for the password when prompted:

```console
$ psql -h primary -U postgres postgres -c 'table pg_stat_replication'
```

If you see a line returned from that query it means the primary is replicating
to the replica.  Try creating some data on the primary:

```console
$ psql -h primary -U postgres postgres -c 'create table foo (id int)'
$ psql -h primary -U postgres postgres -c 'insert into foo values (1)'
```

Then verify that the data is replicated to the replica:

```console
$ psql -h replica -U postgres postgres -c 'table foo'
```

You can scale up the number of read-only replicas by running
the following Kubernetes command:

```console
$ kubectl scale deployment replica --replicas=2
```

It takes 60 seconds for the replica to start and begin replicating
from the primary.

Uninstalling the Chart
----------------------

To uninstall/delete the `primary-replica` deployment:

```console
$ helm del --purge primary-replica
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

Configuration
-------------

See `values.yaml` for configuration notes. Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install basic --name basic \
  --set Image.tag=centos7-10.0-1.6.0
```

The above command changes the image tag of the container from the default of `centos7-9.6.5-1.6.0` to `centos7-10.0-1.6.0`.

> **Tip**: You can use the default [values.yaml](values.yaml)

| Parameter                  | Description                        | Default                                                    |
| -----------------------    | ---------------------------------- | ---------------------------------------------------------- |
| `.name`                 | Name of release.                 | `primary-replica`                                        |
| `.container.port`        | The port used for the primary container      | `5432`                                                      |
| `.container.name.primary`        | Name for the primary container      | `primary`                                                      |
| `.container.name.replica`        | Name for the replica container      | `replica`                                                      |
| `.credentials.primary`                | Password for the primary user    | `password`                                                      |
| `.credentials.root`            | Password for the root user        | `password`                                                      |
| `.credentials.user`            | Password for the standard user   | `password`                                                      |
| `.serviceType`      | The type of service      | `ClusterIP`               
| `.image.repository` | The repository on DockerHub where the images are found.    | `crunchydata`                                           |
| `.image.container` | The container to be pulled from the repository.    | `crunchy-postgres`                                                    |
| `.image.tag` | The image tag to be used.    | `centos7-9.6.5-1.6.0`                                                    |
| `.nfs.serverIP` | The IP address of the NFS server     | 10.0.1.4                                                    |
| `.nfs.path` | The path of the mounted NFS drive    | `/mnt/nfsfileshare`                                                    |
| `.pv.storage` | Size of persistent volume     | 400M                                                    |
| `.pv.name` | Name of persistent volume    | `primary-pv`                                                    |
| `.pvc.name` | Name of persistent volume    | `primary-pvc`                                                    |
| `.resources.cpu` | Defines a limit for CPU    | `200m`                                                    |
| `.resources.memory` | Defines a limit for memory    | `512Mi`                                                    |

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install primary-replica --name primary-replica  \
  -f values.yaml
```

Legal Notices
-------------

Copyright © 2017 Crunchy Data Solutions, Inc.

CRUNCHY DATA SOLUTIONS, INC. PROVIDES THIS GUIDE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF NON INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

Crunchy, Crunchy Data Solutions, Inc. and the Crunchy Hippo Logo are trademarks of Crunchy Data Solutions, Inc.
