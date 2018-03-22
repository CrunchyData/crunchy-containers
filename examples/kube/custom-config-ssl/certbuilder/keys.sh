#!/bin/bash

# Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
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

sudo cp $DIR/openssl.cnf /etc/ssl

# create a private key
openssl genrsa -aes256 -out ca.key 4096
# create a self-signed certificate
openssl req -new -x509 -sha256 -days 1825 -key ca.key -out ca.crt \
	  -subj "/C=US/ST=VA/L=Arlington/O=Crunchy Data Solutions/CN=root-ca"
# create the intermediate CAs
openssl genrsa -aes256 -out server-intermediate.key 4096
# create the server intermediate certificate signing request (CSR)
openssl req -new -sha256 -days 1825 -key server-intermediate.key -out server-intermediate.csr \
	  -subj "/C=US/ST=VA/L=Arlington/O=Crunchy Data Solutions/CN=server-im-ca"
#Create the server intermediate certificate by signing with the CA certificate:
openssl x509 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -req -days 1825 \
	        -CA ca.crt -CAkey ca.key -CAcreateserial \
		        -in server-intermediate.csr -out server-intermediate.crt
# Now repeat the process to create the client intermediate CA:
openssl genrsa -aes256 -out client-intermediate.key 4096

openssl req -new -sha256 -days 1825 -key client-intermediate.key -out client-intermediate.csr \
	  -subj "/C=US/ST=VA/L=Arlington/O=Crunchy Data Solutions/CN=client-im-ca"

openssl x509 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -req -days 1825 \
	        -CA ca.crt -CAkey ca.key -CAcreateserial \
		        -in client-intermediate.csr -out client-intermediate.crt

# Create server/client certificate

# Create a server certificate:
openssl req -nodes -new -newkey rsa:4096 -sha256 -keyout server.key -out server.csr \
	        -subj "/C=US/ST=VA/L=Arlington/O=Crunchy Data Solutions/CN=server.crunchydata.com"

openssl x509 -extfile /etc/ssl/openssl.cnf -extensions usr_cert -req -days 1825 \
	        -CA server-intermediate.crt -CAkey server-intermediate.key \
		        -CAcreateserial -in server.csr -out server.crt
# Create a client certificate:
openssl req -nodes -new -newkey rsa:4096 -sha256 -keyout client.key -out client.csr \
-subj "/C=US/ST=VA/L=Arlington/O=Crunchy Data Solutions/CN=testuser"

openssl x509 -extfile /etc/ssl/openssl.cnf -extensions usr_cert -req -days 1825 \
-CA client-intermediate.crt -CAkey client-intermediate.key \
-CAcreateserial -in client.csr -out client.crt

# set up the psql client access

cp ca.crt ~/.postgresql/root.crt

cp client.key ~/.postgresql/postgresql.key

cat client.crt client-intermediate.crt ca.crt > ~/.postgresql/postgresql.crt

chmod 600 \
      ~/.postgresql/root.crt \
      ~/.postgresql/postgresql.key \
      ~/.postgresql/postgresql.crt
