= DBA (1)
Jeff McCormick
April 13, 2017
== NAME
dba - dba container image

== DESCRIPTION
The dba image provides a very simple form of DBA container that
can monitor a Postgres container and perform backup and vacuum jobs
based on a cron scheduler that is built in.

The container itself consists of:
    - RHEL7 base image
    - bash script that performs the container startup
    - golang executable

Files added to the container during docker build include: /help.1.

== USAGE
See the crunchy docs.


== LABELS
The starter container includes the following LABEL settings:

That atomic command runs the docker command set in this label:

`Name=`

The registry location and name of the image. For example, Name="crunchydata/dba".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.3".

`Release=`

The specific release number of the container. For example, Release="2.0"
