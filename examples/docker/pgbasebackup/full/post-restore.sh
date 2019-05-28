#!/bin/bash

CONTAINER_NAME=pgbasebackup-full-restored

echo "Cleaning up..."

sudo docker stop "${CONTAINER_NAME}"
sudo docker rm "${CONTAINER_NAME}"

docker run \
    -p 12001:5432 \
    --volume full-restore-pgdata:/pgdata \
    --env PG_MODE=primary \
    --env PG_USER=testuser \
    --env PG_PASSWORD=password \
    --env PG_DATABASE=userdb \
    --env PG_PRIMARY_USER=primaryuser \
    --env PG_PRIMARY_PORT=5432 \
    --env PG_PRIMARY_PASSWORD=password \
    --env PG_ROOT_PASSWORD=password \
    --env PGHOST=/tmp \
    --name="${CONTAINER_NAME}" \
    --hostname="${CONTAINER_NAME}" \
    --detach "${CCP_IMAGE_PREFIX?}"/crunchy-postgres:"${CCP_IMAGE_TAG?}"
