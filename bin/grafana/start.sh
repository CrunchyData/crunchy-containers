#!/bin/bash

# Copyright 2018 Crunchy Data Solutions, Inc.
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

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

export PATH=$PATH:/opt/cpm/bin
export GRAFANA_HOME=$(find /opt/cpm/bin/ -type d -name 'grafana-[1-9].*')
export CONFIG_DIR='/opt/cpm/conf'

ls -la /opt/cpm/bin

DASHBOARDS=(
    CRUD_Details
    PostgreSQL
    PostgreSQLDetails
    TableSize_Detail
)

function trap_sigterm() {
    echo_info "Doing trap logic.."
    echo_warn "Clean shutdown of Grafana.."

    if ! pgrep grafana-server > /dev/null
    then
        kill -9 $(pidof grafana-server)
    fi
}

trap 'trap_sigterm' SIGINT SIGTERM

if [[ -f /conf/defaults.ini ]]
then
    echo_info "Custom configuration detected.."
    cp /conf/defaults.ini /data/defaults.ini
else
    echo_info "No custom configuration detected.  Applying default config.."
    env_check_err "ADMIN_USER"
    env_check_err "ADMIN_PASS"
    env_check_err "PROM_HOST"
    env_check_err "PROM_PORT"
    env_check_warn "PROM_USER"
    env_check_warn "PROM_PASS"

    cp ${CONFIG_DIR?}/defaults.ini /data/defaults.ini
    sed -i -e "s|^admin_user = ADMIN_USER$|admin_user = '${ADMIN_USER}'|" /data/defaults.ini
    sed -i -e "s|^admin_password = ADMIN_PASS$|admin_password = '${ADMIN_PASS}'|" /data/defaults.ini

    PROVISION_DIR='/data/grafana/provisioning'
    DASHBOARD_DIR="${PROVISION_DIR?}/dashboards"
    DATASOURCE_DIR="${PROVISION_DIR?}/datasources"
    mkdir -p ${PROVISION_DIR?} ${DASHBOARD_DIR?} ${DATASOURCE_DIR?}

    # Datasource setup
    cp ${CONFIG_DIR?}/prometheus_datasource.yml \
        ${DATASOURCE_DIR?}/crunchy_grafana_datasource.yml
    sed -i -e "s|url: http://PROM_HOST:PROM_PORT|url: http://${PROM_HOST?}:${PROM_PORT?}|" \
        ${DATASOURCE_DIR?}/crunchy_grafana_datasource.yml
    sed -i -e "s|basicAuthUser: PROM_USER|basicAuthUser: ${PROM_USER:-}|"  \
        ${DATASOURCE_DIR?}/crunchy_grafana_datasource.yml
    sed -i -e "s|basicAuthPassword: PROM_PASS|basicAuthPassword: ${PROM_PASS:-}|"  \
        ${DATASOURCE_DIR?}/crunchy_grafana_datasource.yml

    if [[ -z ${PROM_USER:-} ]]
    then
        BASIC_AUTH='false'
    fi
    sed -i -e "s|basicAuth: BASIC_AUTH|basicAuth: ${BASIC_AUTH:-true}|" \
        ${DATASOURCE_DIR?}/crunchy_grafana_datasource.yml

    # Dashboard setup
    cp ${CONFIG_DIR?}/crunchy_grafana_dashboards.yml \
        ${DASHBOARD_DIR?}/crunchy_grafana_dashboards.yml

    sed -i -e "s|/etc/grafana/crunchy_dashboards|${DASHBOARD_DIR?}|" \
        ${DASHBOARD_DIR?}/crunchy_grafana_dashboards.yml

    for dashboard in "${DASHBOARDS[@]}"
    do
        if [[ -f ${CONFIG_DIR?}/${dashboard?}.json ]]
        then
            cp ${CONFIG_DIR?}/${dashboard?}.json ${DASHBOARD_DIR?}
        else
            echo_err "Dashboard ${dashboard?}.json does not exist (it should).."
            exit 1
        fi
    done

    # Set time resolution to 5m so data appears in graphs
    # pgMonitor defaults to 2 days
    sed -i 's/now-2d/now-5m/g' ${DASHBOARD_DIR?}/*.json
fi

echo_info "Starting grafana-server.."

${GRAFANA_HOME?}/bin/grafana-server \
    --config=/data/defaults.ini \
    --homepath=${GRAFANA_HOME?} \
    web &

wait
