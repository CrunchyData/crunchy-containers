#!/bin/bash

# Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
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

source ${CCPROOT}/examples/common.sh
echo_info "Cleaning up.."

cleanup "${CCP_NAMESPACE?}-pgbouncer"

$CCPROOT/examples/waitforterm.sh pgbouncer-primary ${CCP_CLI?}
$CCPROOT/examples/waitforterm.sh pgbouncer-replica ${CCP_CLI?}
$CCPROOT/examples/waitforterm.sh pg-primary ${CCP_CLI?}
$CCPROOT/examples/waitforterm.sh pg-replica ${CCP_CLI?}

rm -f ./pgbouncer-auth.stderr 2>/dev/null
