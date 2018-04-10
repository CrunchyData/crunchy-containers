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


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

mkdir -p ${DIR?}/keys
ssh-keygen -f ${DIR?}/keys/id_rsa -t rsa -N ''
ssh-keygen -t rsa -f ${DIR?}/keys/ssh_host_rsa_key -N ''
ssh-keygen -t ecdsa -f ${DIR?}/keys/ssh_host_ecdsa_key -N ''
ssh-keygen -t ed25519 -f ${DIR?}/keys/ssh_host_ed25519_key -N ''
cp ${DIR?}/keys/id_rsa.pub ${DIR?}/keys/authorized_keys

${CCP_CLI?} create secret generic postgres-sshd-secrets\
    --from-file=ssh-host-rsa=${DIR?}/keys/ssh_host_rsa_key \
    --from-file=ssh-host-ecdsa=${DIR?}/keys/ssh_host_ecdsa_key \
    --from-file=ssh-host-ed25519=${DIR?}/keys/ssh_host_ecdsa_key

${CCP_CLI?} create configmap postgres-sshd-pgconf \
    --from-file ./configs/pgbackrest.conf \
    --from-file ./configs/pg_hba.conf \
    --from-file ./configs/postgresql.conf \
    --from-file ./configs/sshd_config \
    --from-file ./keys/authorized_keys

if [ ! -z "$CCP_STORAGE_CLASS" ]; then
	echo "CCP_STORAGE_CLASS is set. Using the existing storage class for the PV."
	expenv -f $DIR/postgres-sshd-pvc-sc.json | ${CCP_CLI?} create -f -
elif [ ! -z "$CCP_NFS_IP" ]; then
	echo "CCP_NFS_IP is set. Creating NFS based storage volumes."
	expenv -f $DIR/postgres-sshd-pv-nfs.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/postgres-sshd-pvc.json | ${CCP_CLI?} create -f -
else
	echo "CCP_NFS_IP and CCP_STORAGE_CLASS not set. Creating HostPath based storage volumes."
	expenv -f $DIR/postgres-sshd-pv.json | ${CCP_CLI?} create -f -
	expenv -f $DIR/postgres-sshd-pvc.json | ${CCP_CLI?} create -f -
fi

expenv -f $DIR/postgres-sshd.json | ${CCP_CLI?} create -f -
