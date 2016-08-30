#!/bin/bash 

# Copyright 2015 Crunchy Data Solutions, Inc.
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

export PATH=$PATH:/usr/pgsql-9.*/bin

echo $PATH is the path
#mkdir $HOME/.pgadmin
#cp /data/pgadmin4.db $HOME/.pgadmin/
if [ ! -f "$HOME/.pgadmin/config_local.py" ]; then
	echo "WARNING: could not find mounted config files...using defaults which will not get saved if the container is deleted"
	mkdir $HOME/.pgadmin
	cp /opt/cpm/conf/config_local.py $HOME/.pgadmin
	cp /opt/cpm/conf/pgadmin4.db $HOME/.pgadmin
fi
cp $HOME/.pgadmin/config_local.py /usr/lib/python2.7/site-packages/pgadmin4

python /usr/lib/python2.7/site-packages/pgadmin4/pgAdmin4.py

#while true; do
#sleep 1000
#one

