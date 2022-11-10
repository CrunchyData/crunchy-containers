= crunchy-containers (1)
Crunchy Data
December 23, 2019

== NAME
crunchy-containers - Essential open source microservices for production PostgreSQL

== DESCRIPTION
The Crunchy Container Suite provides the essential microservices for running a
enterprise-grade PostgreSQL cluster. These include:

- PostgreSQL
- PostGIS
- pgBackRest
- pgBouncer

and more.

== USAGE
For more information on the Crunchy Container Suite, see the official
[Crunchy Container Suite Documentation](https://access.crunchydata.com/documentation/crunchy-containers/)

== LABELS
The starter container includes the following LABEL settings:

That atomic command runs the Docker command set in this label:

`Name=`

The registry location and name of the image. For example, Name="crunchydata/crunchy-postgres".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.7"

`Release=`

The specific release number of the container. For example, Release="4.7.8"
