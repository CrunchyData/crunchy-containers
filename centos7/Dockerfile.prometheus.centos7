FROM centos:7

LABEL name="crunchydata/prometheus" \
        vendor="crunchy data" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Prometheus server that stores metrics for crunchy-postgres" \
        io.k8s.description="prometheus container" \
        io.k8s.display-name="Crunchy prometheus container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

RUN yum -y update \
 && yum -y install epel-release \
 && yum -y install bind-utils \
    procps-ng \
    hostname  \
    gettext \
  && yum clean all -y

RUN mkdir -p /data /conf /opt/cpm/bin /opt/cpm/conf

ADD prometheus.tar.gz /opt/cpm/bin
ADD bin/prometheus /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/prometheus /opt/cpm/conf

RUN chown -R 2:0 /opt/cpm /data /conf && \
    chmod -R g=u /opt/cpm /data /conf

EXPOSE 9090
VOLUME ["/data", "/conf"]

RUN chmod g=u /etc/passwd
ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
