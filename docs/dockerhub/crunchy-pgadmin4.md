# Crunchy pgAdmin4

![](https://raw.githubusercontent.com/CrunchyData/crunchy-containers/master/images/crunchy_logo.png)

The Crunchy pgAdmin4 docker image contains the following packages:

* pgAdmin4

### Start pgAdmin4 Instance

The following starts a PostgreSQL database and the pgAdmin4 application:

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
    --name=pgadmin4 \
    --hostname=pgadmin4 \
    --publish=5050:5050 \
    --network="pgnet" \
    --env=PGADMIN_SETUP_EMAIL='admin@admin.com' \
    --env=PGADMIN_SETUP_PASSWORD='password' \
    --env=SERVER_PORT='5050' \
    --detach crunchydata/crunchy-pgadmin4:centos7-10.3-1.8.2
```


After deployment, navigate to `0.0.0.0:5050` in a web browser and sign in with the credentials configured above.

See the [Crunchy Blog for a comprehensive example](http://info.crunchydata.com/blog/easy-postgresql-10-and-pgadmin-4-setup-with-docker) on using pgAdmin4.

### Environment Variables

See the [official documentation](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc#crunchy-pgadmin4) for a list of environment variables available for this container.


## More Examples

For more examples, see the [official Crunchy Containers GitHub repository](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/docker).

For more information on pgAdmin4, see the [official pgAdmin4 documentation](https://www.pgadmin.org/docs/pgadmin4/dev/).
