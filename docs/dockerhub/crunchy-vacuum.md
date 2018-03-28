# Crunchy Vacuum

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy Vacuum docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5, 9.6 and 10)

### Start Vacuum Job

The following starts a PostgreSQL and Vacuum container:

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

sleep 10

docker run \
    --name=vacuum \
    --hostname=vacuum \
    --network="pgnet" \
    --env=VAC_VERBOSE=true \
    --env=VAC_FULL=true \
    --env=JOB_HOST=primary \
    --env=VAC_ANALYZE=true \
    --env=VAC_FREEZE=true \
    --env=VAC_TABLE=testtable \
    --env=PG_USER=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_DATABASE=userdb \
    --env=PG_PORT=5432 \
    --detach crunchydata/crunchy-vacuum:centos7-10.3-1.8.2
```

**Note**: Crunchy Vacuum is a short lived job, it should exit `vacuum` is completed.

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-vacuum) for a list of environment variables available for this container.


## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
