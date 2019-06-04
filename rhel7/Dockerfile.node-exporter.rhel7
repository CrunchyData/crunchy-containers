FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/node-exporter" \
        vendor="crunchy data" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Provides host metrics for crunchy-postgres" \
        description="Runs on all container hosts to collect host metrics.  Metrics are stored in Crunchy Prometheus and visualized by Crunchy Grafana" \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="node exporter container" \
        io.k8s.display-name="Crunchy Node Exporter container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database,prometheus,exporter,metrics"

COPY conf/atomic/node-exporter/help.1 /help.1
COPY conf/atomic/node-exporter/help.md /help.md
COPY conf/licenses /licenses

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && yum -y --enablerepo=rhel-7-server-ose-3.11-rpms update \
  && yum -y install \
    bind-utils \
    gettext \
    hostname \
    procps-ng \
  && yum clean all -y

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /host/proc /host/sys

ADD node_exporter.tar.gz /opt/cpm/bin
ADD bin/node-exporter /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/node-exporter /opt/cpm/conf

RUN chgrp -R 0 /opt/cpm/bin /opt/cpm/conf && \
    chmod -R g=u /opt/cpm/bin/ opt/cpm/conf

VOLUME ["/conf"]

# node exporter
EXPOSE 9100

#ENTRYPOINT ["/opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
