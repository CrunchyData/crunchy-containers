# Crunchy Backup

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy Backup docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5, 9.6 and 10)
* pgBaseBackup

### Start Backup Instance

The following deploys a PostgreSQL database and the backup container.  The backup is created in `/tmp/backup`:

```bash
mkdir -p /tmp/backup

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
    --name=backup \
    --hostname=backup \
    --network="pgnet" \
    --volume=/tmp/backup:/pgdata \
    --env=BACKUP_HOST=primary \
    --env=BACKUP_PORT=5432 \
    --env=BACKUP_USER=primaryuser \
    --env=BACKUP_PASS=password \
    --env=BACKUP_LABEL=mybackup \
    --detach crunchydata/crunchy-backup:centos7-10.3-1.8.2
```

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-backup) for a list of environment variables available for this container.


## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
