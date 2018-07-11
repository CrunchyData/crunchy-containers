= upgrade (1)
Jeff McCormick
April 13, 2017
== NAME
upgrade - postgres upgrade container image

== DESCRIPTION
The postgres upgrade image provides pg_upgrade

The container itself consists of:
    - RHEL7 base image
    - bash script that performs the upgrade
    - postgres binary packages for 9.5 and 9.6 postgres

Files added to the container during docker build include: /help.1.

== USAGE
See the crunchy docs.


== LABELS
The starter container includes the following LABEL settings:

That atomic command runs the docker command set in this label:

`Name=`

The registry location and name of the image. For example, Name="crunchydata/upgrade".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.3".

`Release=`

The specific release number of the container. For example, Release="2.0"
