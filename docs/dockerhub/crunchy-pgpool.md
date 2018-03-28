# Crunchy pgPool

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy pgPool docker image contains the following packages:

* pgPool II

### Start pgPool Instance

The following will provision two datbase containers (`primary` and `replica`) and a pgPool container.

```bash
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
    --detach crunchydata/crunchy-postgres:centos7-10.3-1.8.2

docker run \
    --name=replica \
    --hostname=replica \
    --publish=5433:5432 \
    --network="pgnet" \
    --env=PG_MODE=replica \
    --env=PG_PRIMARY_USER=primaryuser \
    --env=PG_PRIMARY_PASSWORD=password \
    --env=PG_PRIMARY_HOST=primary \
    --env=PG_PRIMARY_PORT=5432 \
    --env=PG_DATABASE=userdb \
    --env=PG_USER=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_ROOT_PASSWORD=password \
    --detach crunchydata/crunchy-postgres:centos7-10.3-1.8.2

docker run \
    --name=pgpool \
    --hostname=pgpool \
    --publish=6543:5432 \
    --network="pgnet" \
    --env=PG_PRIMARY_SERVICE_NAME=primary \
    --env=PG_REPLICA_SERVICE_NAME=replica \
    --env=PG_USERNAME=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_DATABASE=userdb \
    --detach crunchydata/crunchy-pgpool:centos7-10.3-1.8.2
```

### Connect via `psql`

Assuming `psql` is installed on the workstation, we can connect to the pooler:

```console
psql -d userdb -h 0.0.0.0 -p 6543 -U testuser -x -c "SELECT now()"
```

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-pgpool) for a list of environment variables available for this container.

### Configuration

The following files can be mounted to `/pgconf/pgpoolconfigdir` to apply custom configuration:

* `pgpool.conf`
* `pool_hba.conf`

For more information on configuring pgPool, see the [official pgPool documentation](http://www.pgpool.net/docs/latest/en/html/runtime-config.html).

## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
