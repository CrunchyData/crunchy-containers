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

set -e

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

CONF_DIR='/data'
PROMETHEUS_PIDFILE=/tmp/prometheus.pid

function trap_sigterm() {
    echo_info "Doing trap logic.."

    echo_warn "Clean shutdown of Prometheus.."
    kill -SIGINT $(head -1 $PROMETHEUS_PIDFILE)
}

trap 'trap_sigterm' SIGINT SIGTERM

if [[ -f /conf/prometheus.yml ]]
then
    echo_info "Custom configuration detected.."
    CONF_DIR='/conf'
else
    # Check if a kube deployment
    if [[ -d /var/run/secrets/kubernetes.io ]]
    then
        echo_info "Kube deployment detected.  Applying kube default config.."
        cp /opt/cpm/conf/prometheus-kube.yml /data/prometheus.yml
    # Docker deployment
    else
        echo_info "Docker deployment detected.  Applying docker default config.."
        cp /opt/cpm/conf/prometheus-docker.yml /data/prometheus.yml
        env_check_err "COLLECT_HOST"
        sed -i "s|COLLECT_HOST|${COLLECT_HOST?}|g" /data/prometheus.yml
    fi
    sed -i "s|SCRAPE_INTERVAL|${SCRAPE_INTERVAL:-5s}|g" /data/prometheus.yml
    sed -i "s|SCRAPE_TIMEOUT|${SCRAPE_TIMEOUT:-5s}|g" /data/prometheus.yml
fi

echo_info "Starting Prometheus.."
/opt/cpm/bin/prometheus*/prometheus --config.file=${CONF_DIR?}/prometheus.yml &
echo $! > $PROMETHEUS_PIDFILE

wait 
