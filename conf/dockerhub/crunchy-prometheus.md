# Crunchy Prometheus

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy Prometheus docker image contains the following packages:

* Prometheus Timeseries Database

### Start Prometheus Instance

The following starts a PostgreSQL database, Collect and Prometheus container:

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
    --detach crunchydata/crunchy-postgres:centos7-10.4-2.0

docker run \
    --name=collect \
    --hostname=collect\
    --network="pgnet" \
    --publish=9187:9187 \
    --publish=9100:9100 \
    --env=DATA_SOURCE_NAME=postgresql://testuser:password@primary:5432/postgres?sslmode=disable \
    --detach crunchydata/crunchy-collect:centos7-10.4-2.0

docker run \
    --name=prometheus \
    --hostname=prometheus \
    --network="pgnet" \
    --publish=9090:9090 \
    --env=COLLECT_HOST=collect \
    --env=SCRAPE_INTERVAL=5s \
    --env=SCRAPE_TIMEOUT=5s \
    --detach crunchydata/crunchy-prometheus:centos7-10.4-2.0
```

### Using Prometheus

To explore metrics in `Prometheus`, in a web browser, navigate to: `http://0.0.0.0:9090/graph`

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-prometheus) for a list of environment variables available for this container.

## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
