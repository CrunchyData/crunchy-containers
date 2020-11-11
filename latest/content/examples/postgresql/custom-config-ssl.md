---
title: "Custom Configuration of PostgreSQL Container with SSL"
date:
draft: false
weight: 3
---

## SSL Authentication

This example shows how you can configure PostgreSQL to use SSL for
client authentication.

The example requires SSL certificates and keys to be created.  Included in
the examples directory is a script to create self-signed certificates (server
and client) for the example: `$CCPROOT/examples/ssl-creator.sh`.

The example creates a client certificate for the user `testuser`.  Furthermore,
the server certificate is created for the server name `custom-config-ssl`.

This example can be run as follows for the Docker environment:
```
cd $CCPROOT/examples/docker/custom-config-ssl
./run.sh
```

And the example can be run in the following directory for the Kubernetes and OpenShift environments:
```
cd $CCPROOT/examples/kube/custom-config-ssl
./run.sh
```

A required step to make this example work is to define
in your `/etc/hosts` file an entry that maps `custom-config-ssl`
to the service IP address for the container.

For instance, if your service has an address as follows:
```
${CCP_CLI} get service
NAME                CLUSTER-IP       EXTERNAL-IP   PORT(S)                   AGE
custom-config-ssl   172.30.211.108   <none>        5432/TCP
```

Then your `/etc/hosts` file needs an entry like this:
```
172.30.211.108 custom-config-ssl
```

For production Kubernetes and OpenShift installations, it will likely be preferred for DNS
names to resolve to the PostgreSQL service name and generate
server certificates using the DNS names instead of the example
name `custom-config-ssl`.

If as a client it's required to confirm the identity of the server, `verify-full` can be
specified for `ssl-mode` in the connection string.  This will check if the server and the
server certificate have the same name.  Additionally, the proper connection parameters
must be specified in the connection string for the certificate information required to
trust and verify the identity of the server (`sslrootcert` and `sslcrl`), and to
authenticate the client using a certificate (`sslcert` and `sslkey`):

```
psql "postgresql://testuser@custom-config-ssl:5432/userdb?\
sslmode=verify-full&\
sslrootcert=$CCPROOT/examples/kube/custom-config-ssl/certs/ca.crt&\
sslcrl=$CCPROOT/examples/kube/custom-config-ssl/certs/ca.crl&\
sslcert=$CCPROOT/examples/kube/custom-config-ssl/certs/client.crt&\
sslkey=$CCPROOT/examples/kube/custom-config-ssl/certs/client.key"
```

To connect via IP, `sslmode` can be changed to `require`.  This will verify the server
by checking the certificate chain up to the trusted certificate authority, but will not
verify that the hostname matches the certificate, as occurs with `verify-full`.  The same
connection parameters as above can be then provided for the client and server certificate
information.

```
psql "postgresql://testuser@IP_OF_PGSQL:5432/userdb?\
sslmode=require&\
sslrootcert=$CCPROOT/examples/kube/custom-config-ssl/certs/ca.crt&\
sslcrl=$CCPROOT/examples/kube/custom-config-ssl/certs/ca.crl&\
sslcert=$CCPROOT/examples/kube/custom-config-ssl/certs/client.crt&\
sslkey=$CCPROOT/examples/kube/custom-config-ssl/certs/client.key"
```

You should see a connection that looks like the following:
```
psql (11.10)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

userdb=>
```
