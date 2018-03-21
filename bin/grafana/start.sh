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

function trap_sigterm() {
    echo_info "Doing trap logic..."
    echo_warn "Clean shutdown of Grafana.."

    if ! pgrep grafana-server > /dev/null
    then
        kill -9 $(pidof grafana-server)
    fi
}

register_dashboards() {
    curl -Ssl "http://${ADMIN_USER?}:${ADMIN_PASS?}@localhost:3000/api/dashboards/import" \
        -X POST \
        -H 'Content-Type: application/json;charset=UTF-8' \
        --data-binary \
        "{\"dashboard\": $(cat ${CONFIG_DIR?}/dashboard.json),
          \"overwrite\": true,
          \"inputs\": [{
              \"name\":     \"DS_PROMETHEUS\",
              \"type\":     \"datasource\",
              \"pluginId\": \"prometheus\",
              \"value\":    \"PROMETHEUS\"
          }]}"
    echo ""
}

register_datasource() {
    curl -Ssl "http://${ADMIN_USER?}:${ADMIN_PASS?}@localhost:3000/api/datasources" \
        -X POST \
        -H 'Content-Type: application/json;charset=UTF-8' \
        --data-binary \
        "$(create_datasource_json_blob)"
    echo ""
}

create_datasource_json_blob() {
  auth='true'
  if [ -z "${PROM_USER}" ] || [ -z "${PROM_PASS}" ]
  then
      auth='false'
  fi

  cat <<EOF
  {
    "name": "PROMETHEUS",
    "type": "prometheus",
    "url": "http://${PROM_HOST?}:${PROM_PORT?}",
    "access": "proxy",
    "isDefault": true,
    "basicAuth": ${auth?},
    "basicAuthUser": "${PROM_USER}",
    "basicAuthPassword": "${PROM_PASS}"
  }
EOF
}

trap 'trap_sigterm' SIGINT SIGTERM

env_check_err "ADMIN_USER"
env_check_err "ADMIN_PASS"
env_check_err "PROM_HOST"
env_check_err "PROM_PORT"
env_check_warn "PROM_USER"
env_check_warn "PROM_PASS"

if [[ -f /conf/defaults.ini ]]
then
    echo_info "Custom configuration detected.."
    cp /conf/defaults.ini /data/defaults.ini
else
    echo_info "No custom configuration detected.  Applying default config.."
    cp ${CONFIG_DIR?}/defaults.ini /data/defaults.ini
    sed -i -e 's|^admin_user = ADMIN_USER$|admin_user = '${ADMIN_USER}'|' /data/defaults.ini
    sed -i -e 's|^admin_password = ADMIN_PASS$|admin_password = '${ADMIN_PASS}'|' /data/defaults.ini
fi

echo_info "Starting grafana-server.."

${GRAFANA_HOME?}/bin/grafana-server \
    --config=/data/defaults.ini \
    --homepath=${GRAFANA_HOME?} \
    web &

sleep 10
echo_info "Registering Prometheus datasource in Grafana.."
register_datasource

echo_info "Importing Grafana dashboards.."
register_dashboards

wait
