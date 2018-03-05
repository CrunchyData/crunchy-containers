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

kubectl delete deploy primary-dc replica-dc replica2-dc
kubectl delete configmap postgresql-conf
kubectl delete secret pguser-secret pgprimary-secret pgroot-secret
sleep 10
kubectl delete service primary-dc
kubectl delete service replica-dc
kubectl delete pvc primary-dc-pgwal-pvc primary-dc-pgbackrest-pvc
