---
title: "Custom Configuration of PostgreSQL Container"
date: 
draft: false
weight: 2
---


## Custom Configuration

You can use your own version of the SQL file `setup.sql` to customize
the initialization of database data and objects when the container and
database are created.

This works by placing a file named `setup.sql` within the `/pgconf` mounted volume
directory.  Portions of the `setup.sql` file are required for the container
to work; please see comments within the sample `setup.sql` file.

If you mount a `/pgconf` volume, crunchy-postgres will look at that directory
for `postgresql.conf`, `pg_hba.conf`, `pg_ident.conf`, SSL server/ca certificates and `setup.sql`.
If it finds one of them it will use that file instead of the default files.

### Docker

This example can be run as follows for the Docker environment:
```
cd $CCPROOT/examples/docker/custom-config
./run.sh
```

### Kubernetes and OpenShift

Running the example:
```
cd $CCPROOT/examples/kube/custom-config
./run.sh
```
