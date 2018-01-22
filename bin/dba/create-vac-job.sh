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

#export TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
#/opt/cpm/bin/oc login https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT --insecure-skip-tls-verify=true --token="$TOKEN"
#/opt/cpm/bin/oc projects $OSE_PROJECT

echo "create-vac-job.sh......"
echo $1 is tempfile
echo $2 is JOB_HOST
echo $3 is CMD

/opt/cpm/bin/$3 delete job $2-vac
sleep 15
/opt/cpm/bin/$3 create -f $1
