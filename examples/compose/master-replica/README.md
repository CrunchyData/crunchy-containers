# Master/Replica Docker Compose Example

This is a `docker-compose` example of deploying a master 
and read replicas using the Crunchy Container image from DockerHub.

## Prerequirements

* [Docker Installed](https://docs.docker.com/engine/installation/) - Tested on 17.06
* [Docker-Compose Installed](https://docs.docker.com/compose/install/) - Tested on 1.14.0

## Deploy

To deploy this example, run the following commands:

```bash
$ git clone git@github.com:CrunchyData/crunchy-containers.git
$ cd ./crunchy-containers/examples/compose/master-replica
$ docker-compose up
```

### Optional: Scale Replica

To deploy more than one replica, run the following:

```bash
$ docker-compose up --scale db-replica=3
```

## Using

To `psql` into the created database containers, first identify the ports exposed 
on the containers:

```bash
$ docker ps
```

Next, using `psql`, connect to the service:

```bash
$ psql -d userdb -h 0.0.0.0 -p <CONTAINER_PORT> -U testuser
```

**Note:** See `PG_PASSWORD` in `docker-compose.yml` for the user password.

## Clean Up

To tear down the example, run the following:

```bash
$ docker-compose stop
$ docker-compose rm
```
