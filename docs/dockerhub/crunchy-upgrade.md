# Crunchy Upgrade

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy Upgrade docker image contains the following packages:

* pg_upgrade

### Start Upgrade Job

The following:

* Creates a PostgreSQL 9.6 container
* Stops the PostgreSQL container
* Creates an Upgrade job
* Upgrades the 9.6 volume to 10
* Starts a PostgreSQL 10 container

```bash
docker network create --driver bridge pgnet

echo "Creating PostgreSQL 9.6 container.."
docker run \
    --name=primary96 \
    --hostname=primary96 \
    --publish=5432:5432 \
    --network="pgnet" \
    --volume=pgdata-96:/pgdata \
    --env=PG_MODE=primary \
    --env=PG_PRIMARY_USER=primaryuser \
    --env=PG_PRIMARY_PASSWORD=password \
    --env=PG_PRIMARY_HOST=primary96 \
    --env=PG_PRIMARY_PORT=5432 \
    --env=PG_DATABASE=userdb \
    --env=PG_USER=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_ROOT_PASSWORD=password \
    --detach crunchydata/crunchy-postgres:centos7-9.6.8-1.8.2

sleep 10

echo "Stopping PostgreSQL 9.6 container.."
docker stop primary96

echo "Upgrading PostgreSQL 9.6 to 10.."
docker run \
    --name=pg_upgrade \
    --hostname=pg_upgrade\
    --network="pgnet" \
    --volume=pgdata-96:/pgolddata:z \
    --volume=pgdata-10:/pgnewdata:z \
    --env=OLD_DATABASE_NAME=primary96 \
    --env=NEW_DATABASE_NAME=primary10 \
    --env=OLD_VERSION=9.6 \
    --env=NEW_VERSION=10 \
    --detach crunchydata/crunchy-upgrade:centos7-10.3-1.8.2

sleep 20

echo "Starting PostgreSQL 10 container.."
docker run \
    --name=primary10 \
    --hostname=primary10 \
    --publish=5432:5432 \
    --network="pgnet" \
    --volume=pgdata-10:/pgdata \
    --env=PG_MODE=primary \
    --env=PG_PRIMARY_USER=primaryuser \
    --env=PG_PRIMARY_PASSWORD=password \
    --env=PG_PRIMARY_HOST=primary10 \
    --env=PG_PRIMARY_PORT=5432 \
    --env=PG_DATABASE=userdb \
    --env=PG_USER=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_ROOT_PASSWORD=password \
    --detach crunchydata/crunchy-postgres:centos7-10.3-1.8.2
    
```

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-upgrade) for a list of environment variables available for this container.


## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
