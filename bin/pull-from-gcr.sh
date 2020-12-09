#!/bin/bash

set -e -u

REGISTRY='us.gcr.io/container-suite'
VERSION=${CCP_IMAGE_TAG?}
GIS_VERSION=${CCP_POSTGIS_IMAGE_TAG?}
IMAGES=(
    crunchy-pgadmin4
    crunchy-pgbadger
    crunchy-pgbouncer
    crunchy-pgpool
    crunchy-postgres
    crunchy-upgrade
    crunchy-postgres-ha
    crunchy-admin
    crunchy-pgbackrest
    crunchy-pgbackrest-repo
)

GIS_IMAGES=(
    crunchy-postgres-gis
    crunchy-postgres-gis-ha
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

for gis_image in "${GIS_IMAGES[@]}"
do
    echo_green "=> Pulling ${REGISTRY?}/${gis_image?}:${GIS_VERSION?}.."
    docker pull ${REGISTRY?}/${gis_image?}:${GIS_VERSION?}
    docker tag ${REGISTRY?}/${gis_image?}:${GIS_VERSION?} crunchydata/${gis_image?}:${GIS_VERSION?}
done

echo_green "=> Done!"

exit 0
