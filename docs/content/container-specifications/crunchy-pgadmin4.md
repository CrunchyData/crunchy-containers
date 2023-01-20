---
title: "crunchy-pgadmin4"
draft: false
---

The crunchy-pgadmin4 container executes the [pgAdmin4](https://www.pgadmin.org/) web application.

pgAdmin4 provides a web user interface to PostgreSQL databases.  A
sample screenshot is below:

![pgAdmin4](/pgadmin4-screenshot.png)

## Features

The following features are supported by the crunchy-pgadmin4 container:

 * Expose port (5050 by default) which is the web server port.
 * Mount a certificate and key to the `/certs` directory and set `ENABLE_TLS` to true to activate HTTPS mode.
 * Set username and password for login via environment variables.

## Restrictions

 * An emptyDir, with write access, must be mounted to the `/run/httpd` directory in OpenShift.

## Packages

The crunchy-pgadmin4 Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL ({{<param postgresVersion13 >}}, {{<param postgresVersion12 >}}, and {{<param postgresVersion11 >}})
* [pgAdmin4](https://www.pgadmin.org/)
* CentOS 7, UBI 8 - publicly available
* UBI 7, UBI 8 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PGADMIN_SETUP_EMAIL**|None|Set this value to the email address used for pgAdmin4 login.
**PGADMIN_SETUP_PASSWORD**|None|Set this value to a password used for pgAdmin4 login. This should be a strong password.
**SERVER_PORT**|5050|Set this value to a change the port pgAdmin4 listens on.
**SERVER_PATH**|/|Set this value to customize the path of the URL that will be utilized to access the pgAdmin4 web application.
**ENABLE_TLS**|FALSE|Set this value to true to enable HTTPS on the pgAdmin4 container. This requires a `server.key` and `server.crt` to be mounted on the `/certs` directory.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
