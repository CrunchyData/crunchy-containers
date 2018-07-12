#!/bin/bash

set -e -u

REGISTRY='us.gcr.io/container-suite'
VERSION=${CCP_IMAGE_TAG?}
IMAGES=(
    crunchy-backrest-restore
    crunchy-backup
    crunchy-collect
    crunchy-dba
    crunchy-pgdump
    crunchy-grafana
    crunchy-pgadmin4
    crunchy-pgbadger
    crunchy-pgbouncer
    crunchy-pgpool
    crunchy-postgres
    crunchy-postgres-gis
    crunchy-prometheus
    crunchy-pgrestore
    crunchy-upgrade
    crunchy-vacuum
    crunchy-watch
)

function echo_green() {
    echo -e "\033[0;32m"
    echo "$1"
    echo -e "\033[0m"
}

gcloud auth login
gcloud config set project container-suite
gcloud auth configure-docker

for image in "${IMAGES[@]}"
do
    echo_green "=> Pulling ${REGISTRY?}/${image?}:${VERSION?}.."
    docker pull ${REGISTRY?}/${image?}:${VERSION?}
    docker tag ${REGISTRY?}/${image?}:${VERSION?} crunchydata/${image?}:${VERSION?}
done

echo_green "=> Done!"

exit 0
