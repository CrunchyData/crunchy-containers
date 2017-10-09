#!/bin/bash
# Copyright 2017 Crunchy Data Solutions, Inc.
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

kubectl delete service master-dc || echo "WARNING: Failed at deleting service (master)."
kubectl delete service replica-dc || echo "WARNING: Failed at deleting service (replica)."
kubectl delete deploy master-dc replica-dc replica2-dc || echo "WARNING: Failed at deleting the 3 deployments."
kubectl delete configmap postgresql-conf || echo "WARNING: Failed at deleting configmap for postgres."
kubectl delete secret pguser-secret pgmaster-secret pgroot-secret || echo "WARNING: Failed at deleting secrets."
