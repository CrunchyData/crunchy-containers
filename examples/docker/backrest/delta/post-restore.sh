#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run \
    --publish 5432:5432 \
    --volume br-pgdata:/pgdata \
    --volume br-backups:/backrestrepo \
    --env PG_MODE=primary \
    --env PG_USER=testuser \
    --env PG_PASSWORD=password \
    --env PG_DATABASE=userdb \
    --env PG_PRIMARY_USER=primaryuser \
    --env PG_PRIMARY_PORT=5432 \
    --env PG_PRIMARY_PASSWORD=password \
    --env PG_ROOT_PASSWORD=password \
    --env PGHOST=/tmp \
    --env PGBACKREST=true \
    --env PGBACKREST_PG1_PATH=/pgdata/backrest \
    --env PGBACKREST_REPO1_PATH=/backrestrepo/backrest-backups \
    --env PGDATA_PATH_OVERRIDE=backrest \
    --name=backrest-delta-restored \
    --hostname=backrest-delta-restored \
    --detach ${CCP_IMAGE_PREFIX?}/crunchy-postgres:${CCP_IMAGE_TAG?}
