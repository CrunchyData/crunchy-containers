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

export PATH=$PATH:/opt/cpm/bin

# get the number of archive files in pg_wal / pg_xlog
if [ "$CCP_PGVERSION" = "9.5" || "$CCP_PGVERSION" = "9.6" ]; then
  find /pgdata/*/pg_xlog/[0-9]* | wc -l
fi
if [ "$CCP_PGVERSION" = "10" ]; then
  find /pgdata/*/pg_wal/[0-9]* | wc -l
fi
