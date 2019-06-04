FROM centos:7

LABEL name="crunchydata/node-exporter" \
    vendor="crunchy data" \
	Version="7.6" \
	Release="2.4.0" \
    url="https://crunchydata.com" \
    summary="Provides host metrics for crunchy-postgres" \
    description="Runs on all container hosts to collect host metrics.  Metrics are stored in Crunchy Prometheus and visualized by Crunchy Grafana" \
    io.k8s.description="node exporter container" \
    io.k8s.display-name="Crunchy Node Exporter container" \
    io.openshift.expose-services="" \
    io.openshift.tags="crunchy,database,prometheus,exporter,metrics"

RUN yum install -y epel-release \
  && yum -y update \
  && yum -y install gettext \
  && yum -y clean all

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

#RUN chmod g=u /etc/passwd

#ENTRYPOINT ["/opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
