#!/bin/bash

set -e -u

REGISTRY=192.168.0.117:5000
VERSION=${CCP_IMAGE_TAG?}
IMAGES=(
    crunchy-postgres
    crunchy-backup
    crunchy-pgpool
    crunchy-pgbouncer
    crunchy-pgdump
    crunchy-pgbench
    crunchy-collect
    crunchy-pgbadger
    crunchy-grafana
    crunchy-pgadmin4
    crunchy-pgrestore
    crunchy-postgres-gis
    crunchy-prometheus
    crunchy-scheduler
    crunchy-upgrade
    crunchy-backrest-restore
    crunchy-postgres-ha
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

echo_green "=> Done!"

exit 0
