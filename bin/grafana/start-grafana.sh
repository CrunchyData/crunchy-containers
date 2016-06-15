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

export PATH=$PATH:/opt/cpm/bin

# overlay grafana defaults with our own
cp /opt/cpm/conf/defaults.ini /opt/cpm/bin/grafana*/conf

# start up grafana server 
cd /opt/cpm/bin/grafana*
./bin/grafana-server web 

while true; do
	echo "sleeping"
	sleep 1000
done

