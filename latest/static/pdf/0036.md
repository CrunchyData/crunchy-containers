---
title: "crunchy-postgres-appdev"
date:
draft: false
---

PostgreSQL (pronounced "post-gress-Q-L") is an open source, ACID compliant, relational database management system (RDBMS) developed by a worldwide team of volunteers. The crunchy-postgres-appdev container image is unmodified, open source PostgreSQL packaged and maintained by professionals.

This image is identical to the crunchy-postgres-gis image except it is built specifically for ease of use for application developers. To achieve that we have set reasonable default for some environment variables, remove some functionality needed for a production usage (such as replication and backup). The **goal** for this image is to get application developers up and going as soon as possible with PostgreSQL with most of the useful extensions and features pre-installed. 

THIS IMAGE COMES WITH NO SUPPORT FROM CRUNCHY DATA. Support on this image is through community work and on a good faith basis. If you need support for your containers please contact Crunchy Data to become a customer. 

This image should NOT be used for production deployment. It shares most of the same configuration as the crunchy-postgres and the crunchy-postgres-gis image. Therefore, you can use this as a test bed for developing your applications that will eventually be used in the supported containers. 


## Features

The following features are supported by the `crunchy-postgres-appdev` container:

* Kubernetes and OpenShift secrets
* Custom mounted configuration files (see below)
* PostGIS
* PL/R

## Packages

The crunchy-postgres-ppdev Docker image contains the following packages (versions vary depending on PostgreSQL version):

* Latest PostgreSQL 
* Latest PostGIS
* CentOS 7, CentOS 8 - publicly available

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PG_PASSWORD**|None|Set this value to specify the password of the user role, if **PG_ROOT_PASSWORD** is unset then it will share this password

### Optional - Common
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PG_DATABASE**|None|Set this value to create an initial database
**PG_PRIMARY_PORT**|5432|Set this value to configure the primary PostgreSQL port.  It is recommended to use 5432.
**PG_USER**|None|Set this value to specify the username of the general user account
**PG_ROOT_PASSWORD**|None|Set this value to specify the password of the superuser role. If unset it is the same as the password **PG_PASSWORD**

### Optional - Other
**Name**|**Default**|**Description**
:-----|:-----|:-----
**ARCHIVE_MODE**|Off|Set this value to `on` to enable continuous WAL archiving
**ARCHIVE_TIMEOUT**|60|Set to a number (in seconds) to configure `archive_timeout` in `postgresql.conf`
**CHECKSUMS**|Off|Enables `data-checksums` during initialization of the database.  Can only be set during initial database creation.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
**LOG_STATEMENT**|none|Sets the `log_statement` value in `postgresql.conf`
**LOG_MIN_DURATION_STATEMENT**|60000|Sets the `log_min_duration_statement` value in `postgresql.conf`
**MAX_CONNECTIONS**|100|Sets the `max_connections` value in `postgresql.conf`
**PG_LOCALE**|UTF-8|Set the locale of the database
**PGAUDIT_ANALYZE**|None|Set this to enable `pgaudit_analyze`
**PGBOUNCER_PASSWORD**|None|Set this to enable `pgBouncer` support by creating a special `pgbouncer` user for authentication through the connection pooler.
**PGDATA_PATH_OVERRIDE**|None|Set this value to override the `/pgdata` directory name.  By default `/pgdata` uses `hostname` of the container.  In some cases it may be required to override this with a custom name
**SHARED_BUFFERS**|128MB|Set this value to configure `shared_buffers` in `postgresql.conf`
**TEMP_BUFFERS**|8MB|Set this value to configure `temp_buffers` in `postgresql.conf`
**WORK_MEM**|4MB|Set this value to configure `work_mem` in `postgresql.conf`
**XLOGDIR**|None| Set this value to configure PostgreSQL to send WAL to the `/pgwal` volume (by default WAL is stored in `/pgdata`)
**PG_CTL_OPTS**|None| Set this value to supply custom `pg_ctl` options (ex: `-c shared_preload_libraries=pgaudit`) during the initialization phase the container start.

## Volumes

**Name**|**Description**
:-----|:-----
**/pgconf**|Volume used to store custom configuration files mounted to the container.
**/pgdata**|Volume used to store the data directory contents for the PostgreSQL database.

## Custom Configuration

The following configuration files can be mounted to the `/pgconf` volume in the `crunchy-postgres` container to customize the runtime:

**Name**|**Description**
:-----|:-----
`ca.crt`| Certificate of the CA used by the server when using SSL authentication
`ca.crl`| Revocation list of the CA used by the server when using SSL authentication
`pg_hba.conf`| Client authentication rules for the database
`pg_ident.conf`| Mapping of external users (such as SSL certs, GSSAPI, LDAP) to database users
`postgresql.conf`| PostgreSQL settings
`server.key`| Key used by the server when using SSL authentication
`server.crt`| Certificate used by the server when using SSL authentication
`setup.sql`|Custom SQL to execute against the database.  Note: only run during the first startup (initialization)

## Verifying PL/R

In order to verify the successful initialization of the PL/R extension, the following commands can be run:

```sql
create extension plr;
SELECT * FROM plr_environ();
SELECT load_r_typenames();
SELECT * FROM r_typenames();
SELECT plr_array_accum('{23,35}', 42);
CREATE OR REPLACE FUNCTION plr_array (text, text)
RETURNS text[]
AS '$libdir/plr','plr_array'
LANGUAGE 'c' WITH (isstrict);
select plr_array('hello','world');
```
