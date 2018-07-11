# Crunchy Backrest Restore

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy Backrest Restore docker image contains the following packages:

* pgBackRest

### Start `DELTA` pgBackRest Restore Job

The following example: 
* creates a PostgreSQL container
* creates a pgBackRest backup
* stops the database
* executes a `delta` restore using the backrest-restore container
* starts the restored database

```bash
mkdir -p /tmp/pgbackrest/configs

cat << EOF > /tmp/pgbackrest/configs/pgbackrest.conf
[db]
db-path=/pgdata/primary

[global]
repo-path=/backrestrepo
log-path=/pgdata
EOF

docker network create --driver bridge pgnet

echo "Creating PostgreSQL container.."
docker run \
    --name=primary \
    --hostname=primary \
    --publish=5432:5432 \
    --network="pgnet" \
    --volume=/tmp/pgbackrest/configs:/pgconf:z \
    --volume=pgdata:/pgdata:z \
    --volume=backrestrepo:/backrestrepo:z \
    --env=PG_MODE=primary \
    --env=PGHOST=/tmp \
    --env=PG_PRIMARY_USER=primaryuser \
    --env=PG_PRIMARY_PASSWORD=password \
    --env=PG_PRIMARY_HOST=primary \
    --env=PG_PRIMARY_PORT=5432 \
    --env=PG_DATABASE=userdb \
    --env=PG_USER=testuser \
    --env=PG_PASSWORD=password \
    --env=PG_ROOT_PASSWORD=password \
    --env=ARCHIVE_TIMEOUT=60 \
    --detach crunchydata/crunchy-postgres:centos7-10.4-2.0

sleep 20

echo "Taking a pgBackRest backup.."
docker exec -ti primary pgbackrest --stanza=db --config=/pgconf/pgbackrest.conf backup

echo "Stopping primary to prepare for restore.."
docker stop primary

echo "Creating DELTA restore job.."
docker run \
    --name=backrest-restore \
    --hostname=backrest-restore \
    --network="pgnet" \
    --volume=/tmp/pgbackrest/configs:/pgconf:z \
    --volume=pgdata:/pgdata:z \
    --volume=backrestrepo:/backrestrepo:z \
    --env=STANZA=db \
    --env=DELTA=true \
    --detach crunchydata/crunchy-backrest-restore:centos7-10.4-2.0

sleep 20

echo "Starting primary.."
docker start primary
```

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-backrest-restore) for a list of environment variables available for this container.

### Configuration

pgBackRest can be configured by mounting a `pgbackrest.conf` file to `/pgconf`.

For more information on configurations available in pgBackRest, see the [official documentation](https://pgbackrest.org/).

## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
