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

echo "creating restoredmaster volume..."
docker volume rm restoredmaster-volume

docker volume create --name=restoredmaster-volume \
-d pxd --opt name=restoredmaster-volume --opt size=500M \
--opt block_size=64 --opt repl=1 --opt fs=ext4 --opt uid=26
