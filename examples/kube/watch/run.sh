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

${CCP_CLI?} create configmap watch-hooks-configmap \
                --from-file=./hooks/watch-pre-hook \
                --from-file=./hooks/watch-post-hook

${CCP_CLI?} create -f $DIR/watch-sa.json

${CCP_CLI?} create rolebinding pg-watcher-sa-edit \
  --clusterrole=edit \
  --serviceaccount=$CCP_NAMESPACE:pg-watcher \
  --namespace=$CCP_NAMESPACE

envsubst < $DIR/watch.yaml | ${CCP_CLI?} create -f -
