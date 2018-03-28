# Crunchy pgBouncer

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy pgBouncer docker image contains the following packages:

* pgBouncer

### Start pgBouncer Instance

The following creates two database containers (`primary` and `replica`) and a pgBouncer connection pooler:

```bash
mkdir -p /tmp/pgbouncer/configs

cat << EOF > /tmp/pgbouncer/configs/pgbouncer.ini
[databases]
primary = host=primary port=5432 dbname=userdb
replica = host=replica port=5432 dbname=userdb

[pgbouncer]
listen_port = 5432
listen_addr = 0.0.0.0
auth_type = md5
auth_file = /pgconf/bouncerconfig/users.txt
logfile = /tmp/pgbouncer.log
pidfile = /tmp/pgbouncer.pid
admin_users = testuser
max_db_connections = 5
default_pool_size = 5
EOF

cat << EOF > /tmp/pgbouncer/configs/users.txt
"testuser" "password"
EOF

docker network create --driver bridge pgnet

docker run \
    --name=primary \
    --hostname=primary \
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
    --name=pgbouncer \
    --hostname=pgbouncer \
    --publish=5432:5432 \
    --volume=/tmp/pgbouncer/configs:/pgconf/bouncerconfig:z \
    --network="pgnet" \
    --detach crunchydata/crunchy-pgbouncer:centos7-10.3-1.8.2
```

### Using with `psql`

To use the pgBouncer connection pooler deployed above, assuming `psql` is installed on the workstation, run the following:

#### Primary

```console
psql -d primary -h 0.0.0.0 -p 5432 -U testuser -c "SELECT now()"
```
#### Replica

```
psql -d replica -h 0.0.0.0 -p 5432 -U testuser -c "SELECT now()"
```

#### pgBouncer Adminstration

To access the administrator database for pgBouncer, assuming `psql` is installed on the workstation, run the following:

```console
psql -d pgbouncer -h 0.0.0.0 -p 5432 -U testuser -c "SHOW SERVERS"
```

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-pgbouncer) for a list of environment variables available for this container.

### Configuration

As shown above, two configuration files can be mounted to `/pgconf/bouncerconfig` for configuring pgBouncer:

* `pgbouncer.ini`
* `users.txt`

For more information on configuring pgBouncer, see the [official pgBouncer documentation](https://pgbouncer.github.io/config.html).

## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).
