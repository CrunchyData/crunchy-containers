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


sudo docker run --restart=always --name px-dev -d --net=host --privileged=true \
-v /run/docker/plugins:/run/docker/plugins                       \
-v /var/lib/osd:/var/lib/osd:shared                              \
-v /dev:/dev                                                     \
-v /etc/pwx:/etc/pwx                                             \
-v /opt/pwx/bin:/export_bin:shared                               \
-v /var/run/docker.sock:/var/run/docker.sock                     \
-v /var/cores:/var/cores                                         \
-v /usr/src:/usr/src                                             \
--ipc=host                                                       \
portworx/px-dev
