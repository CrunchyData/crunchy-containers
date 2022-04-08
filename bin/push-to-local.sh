#!/bin/bash

set -e -u

REGISTRY=192.168.0.117:5000
VERSION=${CCP_IMAGE_TAG?}
GIS_VERSION=${CCP_POSTGIS_IMAGE_TAG?}
IMAGES=(
    crucnhy-pgbackrest
    crunchy-pgbouncer
    crunchy-postgres
    crunchy-upgrade
    # crunchy-pgadmin4
    # crunchy-pgbadger
    # crunchy-pgpool
)

GIS_IMAGES=(
    crunchy-postgres-gis
)

function echo_green() {
    echo -e "\033[0;32m"
    echo "$1"
    echo -e "\033[0m"
}

for image in "${IMAGES[@]}"
do
    echo_green "=> Pushing ${REGISTRY?}/$CCP_IMAGE_PREFIX/${image?}:${VERSION?}.."
    docker tag $CCP_IMAGE_PREFIX/${image?}:${VERSION?} ${REGISTRY?}/$CCP_IMAGE_PREFIX/${image?}:${VERSION?}
    docker push ${REGISTRY?}/$CCP_IMAGE_PREFIX/${image?}:${VERSION?}
done

for gis_image in "${IMAGES[@]}"
do
    echo_green "=> Pushing ${REGISTRY?}/$CCP_IMAGE_PREFIX/${gis_image?}:${GIS_VERSION?}.."
    docker tag $CCP_IMAGE_PREFIX/${image?}:${GIS_VERSION?} ${REGISTRY?}/$CCP_IMAGE_PREFIX/${gis_image?}:${GIS_VERSION?}
    docker push ${REGISTRY?}/$CCP_IMAGE_PREFIX/${gis_image?}:${GIS_VERSION?}
done

echo_green "=> Done!"

exit 0
