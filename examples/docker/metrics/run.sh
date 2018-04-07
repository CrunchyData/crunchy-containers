#!/bin/bash

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$DIR/cleanup.sh

echo "Starting the metrics example..."

docker volume create --driver local --name=metrics-data
docker volume create --driver local --name=pgsql-pgdata
docker network create --driver bridge pgnet

echo "Starting the PostgreSQL container..."
docker run \
    --name="crunchy-pgsql" \
    --hostname="crunchy-pgsql" \
    -p 12015:5432 \
    -v pgsql-pgdata:/pgdata \
    --network="pgnet" \
    --env-file=./env/pgsql.list \
    -d $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG

echo "Starting the Collect container..."
docker run \
    --name="crunchy-collect" \
    --hostname="crunchy-collect" \
    --network="pgnet" \
    --env-file=./env/collect.list \
    -d ${CCP_IMAGE_PREFIX?}/crunchy-collect:${CCP_IMAGE_TAG?}

echo "Starting the Prometheus container..."
docker run \
    --name="crunchy-prometheus" \
    --hostname="crunchy-prometheus" \
    -p 9090:9090 \
    -v metrics-data:/data \
    --network="pgnet" \
    --env-file=./env/prometheus.list \
    -d ${CCP_IMAGE_PREFIX?}/crunchy-prometheus:${CCP_IMAGE_TAG?}

echo "Starting the Grafana container..."
docker run \
    --name="crunchy-grafana" \
    --hostname="crunchy-grafana" \
    -p 3000:3000 \
    -v metrics-data:/data \
    --network="pgnet" \
    --env-file=./env/grafana.list \
    -d ${CCP_IMAGE_PREFIX?}/crunchy-grafana:${CCP_IMAGE_TAG?}

exit 0
