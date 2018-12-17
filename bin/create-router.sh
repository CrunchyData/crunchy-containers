#!/bin/bash
# Copyright 2016 - 2019 Crunchy Data Solutions, Inc.
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


docker pull registry.access.redhat.com/openshift3/ose-haproxy-router:latest

export CA=/etc/origin/master
oadm ca create-server-cert --signer-cert=$CA/ca.crt \
	      --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt \
	            --hostnames='*.apps.crunchy.lab' \
		          --cert=cloudapps.crt --key=cloudapps.key


cat cloudapps.crt cloudapps.key $CA/ca.crt > cloudapps.router.pem


oadm router --replicas=1 --default-cert=cloudapps.router.pem --credentials='/etc/origin/master/openshift-router.kubeconfig' --service-account=router

iptables -I OS_FIREWALL_ALLOW -p tcp -m tcp --dport 1936 -j ACCEPT


