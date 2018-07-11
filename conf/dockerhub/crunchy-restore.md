# Crunchy Restore

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy Restore docker image contains the following packages:

* pg_restore

### Start Restore Job

The following creates a PostgreSQL database, takes a logical backup (pgdump) and restores from that backup:

```bash
mkdir -p /tmp/pgdump

docker network create --driver bridge pgnet

docker run \
    --name=primary \
    --hostname=primary \
    --publish=5432:5432 \
    --network="pgnet" \
    --env=PG_MODE=primary \
    --env=PG_PRIMARY_USER=primaryuser \
    --env=PG_PRIMARY_PASSWORD=password \
    --env=PG_PRIMARY_HOST=primary \
    --env=PG_PRIMARY_PORT=5432 \
    --env=PG_DATABASE=userdb \
    --env=PG_USER=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_ROOT_PASSWORD=password \
    --detach crunchydata/crunchy-postgres:centos7-10.4-2.0

sleep 10

docker run \
    --name=pgdump \
    --hostname=pgdump \
    --network="pgnet" \
    --volume=/tmp/pgdump:/pgdata:z \
    --env=PGDUMP_ALL=true \
    --env=PGDUMP_HOST=primary \
    --env=PGDUMP_DB=userdb \
    --env=PGDUMP_USER=postgres \
    --env=PGDUMP_PASS=password \
    --env=PGDUMP_PORT=5432 \
    --env=PGDUMP_LABEL=mybackup \
    --env=PGDUMP_FORMAT=plain \
    --env=PGDUMP_VERBOSE=true \
    --detach crunchydata/crunchy-pgdump:centos7-10.4-2.0

sleep 10

BACKUP_DIR="$(find /tmp/pgdump/primary-dumps -type d -name '20*' | head -n 1)"
docker run \
    --name=pgrestore \
    --hostname=pgrestore \
    --network="pgnet" \
    --volume="${BACKUP_DIR?}:/pgrestore:z" \
    --env=PGRESTORE_HOST=primary \
    --env=PGRESTORE_DB=postgres \
    --env=PGRESTORE_USER=postgres \
    --env=PGRESTORE_PASS=password \
    --env=PGRESTORE_PORT=5432 \
    --env=PGRESTORE_LABEL=myrestore \
    --env=PGRESTORE_FILE="pgdumpall.sql" \
    --env=PGRESTORE_VOLUMEPATH='/pgrestore' \
    --env=PGRESTORE_FORMAT=plain \
    --detach crunchydata/crunchy-pgrestore:centos7-10.4-2.0
```

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-pgrestore) for a list of environment variables available for this container.


## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
