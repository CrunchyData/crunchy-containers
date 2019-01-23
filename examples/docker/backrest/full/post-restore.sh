#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run \
    --publish 5432:5432 \
    --volume br-new-pgdata:/pgdata \
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
    --env PGBACKREST_REPO1_PATH=/backrestrepo/backrest-backups \
    --name=backrest-full-restored \
    --hostname=backrest-full-restored \
    --detach ${CCP_IMAGE_PREFIX?}/crunchy-postgres:${CCP_IMAGE_TAG?}
