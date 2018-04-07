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

echo "Cleaning up..."

PITR_CONTAINER_NAME=pitr
BACKUP_CONTAINER_NAME=backup-pitr
RESTORE_CONTAINER_NAME=restore-pitr

docker stop $PITR_CONTAINER_NAME
docker rm -v $PITR_CONTAINER_NAME

docker stop $BACKUP_CONTAINER_NAME
docker rm -v $BACKUP_CONTAINER_NAME

docker stop $RESTORE_CONTAINER_NAME
docker rm -v $RESTORE_CONTAINER_NAME
