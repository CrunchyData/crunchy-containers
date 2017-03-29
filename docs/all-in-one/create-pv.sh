#!/bin/bash
# Copyright 2016 Crunchy Data Solutions, Inc.
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

source $CCPROOT/examples/envvars.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

kubectl delete pv nfs-pv-01 nfs-pv-02 nfs-pv-03 nfs-pv-04 nfs-pv-05
kubectl delete pv nfs-pv-06 nfs-pv-07 nfs-pv-08 nfs-pv-09 nfs-pv-10
envsubst < $DIR/nfs-pv-01.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-02.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-03.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-04.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-05.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-06.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-07.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-08.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-09.json |  kubectl create -f -
envsubst < $DIR/nfs-pv-10.json |  kubectl create -f -
