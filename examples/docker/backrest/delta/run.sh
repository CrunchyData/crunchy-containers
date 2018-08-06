#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

docker run \
    --volume br-pgdata:/pgdata \
    --volume br-backups:/backrestrepo \
    --volume ${DIR?}/configs:/pgconf \
    --env STANZA=db \
    --env DELTA=true \
    --name=backrest-delta-restore \
    --hostname=backrest-delta-restore \
    --detach ${CCP_IMAGE_PREFIX?}/crunchy-backrest-restore:${CCP_IMAGE_TAG?}
