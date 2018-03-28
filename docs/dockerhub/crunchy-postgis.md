# Crunchy Postgres GIS

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy Postgres GIS docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5, 9.6 and 10)
* PostGIS (2.2, 2.3 and 2.4)
* PostGIS SFCGAL
* Postgis Tiger Geocoder
* Postgis Topology
* PL/R
* pgBackRest

## Using the Image

### Start PostGIS Instance

The following starts a PostGIS container:

```bash
$ docker run \
    --name=postgis \
    --hostname=postgis \
    --publish=5432:5432 \
    --env=PG_MODE=primary \
    --env=PG_PRIMARY_USER=primaryuser \
    --env=PG_PRIMARY_PASSWORD=password \
    --env=PG_PRIMARY_HOST=localhost \
    --env=PG_PRIMARY_PORT=5432 \
    --env=PG_DATABASE=userdb \
    --env=PG_USER=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_ROOT_PASSWORD=password \
    --detach crunchydata/crunchy-postgres-gis:centos7-10.3-1.8.2
```

### Connect via `psql`

```bash
$ docker exec -ti postgis psql -U postgres -d postgres -h 0.0.0.0
```

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#environment-variables) for a list of environment 
variables available for this container.

### Configuration

The following files can be mounted to `/pgdata` to apply custom configuration:

* `postgresql.conf`
* `pg_hba.conf`
* `pgbackrest.conf`

In addition to configuration files, custom SQL can be executed by mounting a `setup.sql` 
file to `/pgdata`.

## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
