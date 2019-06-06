FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/prometheus" \
        vendor="crunchy data" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Prometheus server that stores metrics for crunchy-postgres" \
        description="PostgreSQL collected metrics are stored here as defined by the Crunchy Container Suite.  Prometheus will scrape metrics from Crunchy Collect. Works in conjunction with crunchy-collect and crunchy-grafana." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="prometheus container" \
        io.k8s.display-name="Crunchy prometheus container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/prometheus/help.1 /help.1
COPY conf/atomic/prometheus/help.md /help.md
COPY conf/licenses /licenses

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && yum -y --enablerepo=rhel-7-server-ose-3.11-rpms update \
  && yum -y install \
    bind-utils \
    gettext \
    hostname \
    procps-ng \
  && yum clean all -y

RUN mkdir -p /data /conf /opt/cpm/bin /opt/cpm/conf

ADD prometheus.tar.gz /opt/cpm/bin
ADD bin/prometheus /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/prometheus /opt/cpm/conf

RUN chown -R 2:0 /opt/cpm /data && \
    chmod -R g=u /opt/cpm /data

EXPOSE 9090
VOLUME ["/data", "/conf"]

RUN chmod g=u /etc/passwd
ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
