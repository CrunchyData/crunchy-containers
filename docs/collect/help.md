= collect (1)
Jeff McCormick
April 13, 2017
== NAME
collect - collect container image

== DESCRIPTION
PostgreSQL metrics collection container. Every 3 minutes the collection container will collect PostgreSQL metrics and push them to the Crunchy Prometheus database. These can be graphed using the Crunchy grafana container.

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

The registry location and name of the image. For example, Name="crunchydata/collect".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.3".

`Release=`

The specific release number of the container. For example, Release="1.6.0"
