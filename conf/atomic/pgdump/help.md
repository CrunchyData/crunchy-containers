= pgdump (1)
Crunchy Data
March 2018
== NAME
pgdump - pgdump container image

== DESCRIPTION
The pgdump image provides a means of performing a full database
pgdump on a Postgres container database.

The container itself consists of:
    - RHEL7 base image
    - bash script that performs the container startup
    - Postgres binary packages

Files added to the container during docker build include: /help.1.

== USAGE
See the crunchy docs.


== LABELS
The starter container includes the following LABEL settings:

That atomic command runs the docker command set in this label:

`Name=`

The registry location and name of the image. For example, Name="crunchydata/crunchy-pgdump".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.3".

`Release=`

The specific release number of the container. For example, Release="2.0"
