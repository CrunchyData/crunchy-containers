= node exporter (1)
Crunchy Data
May 20, 2019
== NAME
node exporter- node exporter container image

== DESCRIPTION
Host metrics collection container. Every 5 seconds the collection container will collect host metrics which can be scrapped by Crunchy Prometheus container. These can be graphed using the Crunchy Grafana container.

The container itself consists of:
    - RHEL7 base image
    - Node Exporter
    - bash script that performs the container startup

Files added to the container during docker build include: /help.1.

== USAGE
See the crunchy docs.


== LABELS
The starter container includes the following LABEL settings:

That atomic command runs the docker command set in this label:

`Name=`

The registry location and name of the image. For example, Name="crunchydata/node-exporter".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.6"

`Release=`

The specific release number of the container. For example, Release="2.4.0"
