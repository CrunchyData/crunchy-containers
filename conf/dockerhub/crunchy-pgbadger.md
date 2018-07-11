# Crunchy pgBadger

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy pgBadger docker image contains the following packages:

* pgBadger Log Analyzer

### Start pgBadger Instance

The following starts a PostgreSQL database and pgBadger container:

```bash
docker network create --driver bridge pgnet

docker run \
    --name=primary \
    --hostname=primary \
    --publish=5432:5432 \
    --network="pgnet" \
    --volume=pgdata:/pgdata:z \
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

docker run \
    --name=pgbadger \
    --hostname=pgbadger \
    --publish=10000:10000 \
    --network="pgnet" \
    --volume=pgdata:/pgdata:z \
    --env=BADGER_TARGET='primary' \
    --detach crunchydata/crunchy-pgbadger:centos7-10.4-2.0
```

### Using pgBadger

To generate a report, in a web browser, nagivate to: `http://0.0.0.0:10000/api/badgergenerate`

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-pgbadger) for a list of environment variables available for this container.

## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
