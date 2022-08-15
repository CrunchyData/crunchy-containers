---
title: "PostGIS Container"
date:
draft: false
weight: 8
---


## Geospatial (PostGIS)

An example is provided that will run a PostgreSQL with PostGIS pod and service in Kubernetes and OpenShift and a container in Docker.

The container creates a default database called *userdb*, a default user called
*testuser* and a default password of *password*.

You can view the extensions that postgres-gis has enabled by running the following command and viewing the listed PostGIS packages:
```
psql -h postgres-gis -U testuser userdb -c '\dx'
```

To validate that PostGIS is installed and which version is running, run the command:

```
psql -h postgres-gis -U testuser userdb -c "SELECT postgis_full_version();"
```

You should expect to see output similar to:

```
postgis_full_version
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 POSTGIS="2.4.8 r16113" PGSQL="100" GEOS="3.5.0-CAPI-1.9.0 r4084" PROJ="Rel. 4.8.0, 6 March 2012" GDAL="GDAL 1.11.4, released 2016/01/25" LIBXML="2.9.1" LIBJSON="0.11" TOPOLOGY RASTER
(1 row)
```

As an exercise for invoking some of the basic PostGIS functionality for validation, try defining a 2D geometry point while giving inputs of
longitude and latitude through this command.

```
psql -h postgres-gis -U testuser userdb -c "select ST_MakePoint(28.385200,-81.563900);"
```

You should expect to see output similar to:

```
                st_makepoint
--------------------------------------------
 0101000000516B9A779C623C40B98D06F0166454C0
(1 row)
```

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Docker

Create the container as follows:
```
cd $CCPROOT/examples/docker/postgres-gis
./run.sh
```

Enter the following command to connect to the postgres-gis container that is
mapped to your local port 12000:
```
psql -h localhost -U testuser -p 12000 userdb
```

### Kubernetes and OpenShift

Running the example:
```
cd $CCPROOT/examples/kube/postgres-gis
./run.sh
```
