= pgadmin4 (1)
Crunchy Data
April 13, 2017
== NAME
pgadmin4 - pgadmin4 container image

== DESCRIPTION
The pgadmin4 image provides the open source pgadmin4 web user interface
program for managing and viewing postgres databases.

The container itself consists of:
    - RHEL7 base image
    - bash script that performs the container startup
    - pgadmin4 binary packages

Files added to the container during docker build include: /help.1.

== USAGE
See the crunchy docs.


== LABELS
The starter container includes the following LABEL settings:

That atomic command runs the docker command set in this label:

`Name=`

The registry location and name of the image. For example, Name="crunchydata/pgadmin4".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.3".

`Release=`

The specific release number of the container. For example, Release="2.0"
