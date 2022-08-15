---
title: "pgBouncer"
date:
draft: false
weight: 51
---

## pgBouncer Connection Pooling Example


Crunchy pgBouncer is a lightweight connection pooler for PostgreSQL databases.

The following examples create the following containers:

  * pgBouncer Primary
  * pgBouncer Replica
  * PostgreSQL Primary
  * PostgreSQL Replica

In Kubernetes and OpenShift, this example will also create:

  * pgBouncer Primary Service
  * pgBouncer Replica Service
  * Primary Service
  * Replica Service
  * PostgreSQL Secrets
  * pgBouncer Secrets

To cleanup the objects created by this example, run the following in the `pgbouncer` example directory:

```
./cleanup.sh
```

{{% notice tip %}}
For more information on `pgBouncer`, see the [official website](https://pgbouncer.github.io).
{{% /notice %}}


This example uses a custom configuration to create the pgbouncer user and an auth function in 
the primary for the pgbouncer containers to authenticate against. It takes advantage of the post-startup-hook and
a custom sql file mounted in the /pgconf directory.


### Docker

Run the `pgbouncer` example:
```
cd $CCPROOT/examples/docker/pgbouncer
./run.sh
```

Once all containers have deployed and are ready for use, `psql` to the target
databases through `pgBouncer`:

```
psql -d userdb -h 0.0.0.0 -p 6432 -U testuser
psql -d userdb -h 0.0.0.0 -p 6433 -U testuser
```

To connect to the administration database within `pgbouncer`, connect using `psql`:

```
psql -d pgbouncer -h 0.0.0.0 -p 6432 -U pgbouncer
psql -d pgbouncer -h 0.0.0.0 -p 6433 -U pgbouncer
```

### Kubernetes and OpenShift

{{% notice tip %}}
OpenShift: If custom configurations aren't being mounted, an *emptydir* volume is required
to be mounted at `/pgconf`.
{{% /notice %}}

Run the `pgbouncer` example:
```
cd $CCPROOT/examples/kube/pgbouncer
./run.sh
```

Once all containers have deployed and are ready for use, `psql` to the target
databases through `pgBouncer`:

```
psql -d userdb -h pgbouncer-primary -p 6432 -U testuser
psql -d userdb -h pgbouncer-replica -p 6432 -U testuser
```

To connect to the administration database within `pgbouncer`, connect using `psql`:

```
psql -d pgbouncer -h pgbouncer-primary -p 6432 -U pgbouncer -c "SHOW SERVERS"
psql -d pgbouncer -h pgbouncer-replica -p 6432 -U pgbouncer -c "SHOW SERVERS"
```
