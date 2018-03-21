= postgres (1)
Jeff McCormick
April 13, 2017
== NAME
postgres - postgres container image

== DESCRIPTION
The postgres image provides the open source Postgres database.

The container itself consists of:
    - RHEL7 base image
    - bash script that performs the container startup
    - postgres binary packages

Files added to the container during docker build include: /help.1.

== USAGE
See the crunchy docs.


== LABELS
The starter container includes the following LABEL settings:

That atomic command runs the docker command set in this label:

`Name=`

The registry location and name of the image. For example, Name="crunchydata/postgres".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.3".

`Release=`

The specific release number of the container. For example, Release="1.8.2"
