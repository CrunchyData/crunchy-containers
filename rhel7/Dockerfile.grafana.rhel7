FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/grafana" \
        vendor="crunchy data" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Provides a Grafana web dashboard to view collected PostgreSQL metrics" \
        description="Connect this container to the crunchy-prometheus container as a data source, then use the metrics to build dashboards. Works in conjunction with crunchy-collect and crunchy-prometheus." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="grafana container" \
        io.k8s.display-name="Crunchy grafana container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/grafana/help.1 /help.1
COPY conf/atomic/grafana/help.md /help.md
COPY conf/licenses /licenses

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && yum -y --enablerepo=rhel-7-server-ose-3.11-rpms update \
  && yum -y install \
    bind-utils \
    gettext \
    hostname \
    procps-ng \
  && yum clean all -y

RUN mkdir -p /data /opt/cpm/bin /opt/cpm/conf

ADD grafana.tar.gz /opt/cpm/bin
ADD tools/pgmonitor/grafana /opt/cpm/conf
ADD bin/grafana /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/grafana /opt/cpm/conf

RUN chown -R 2:0 /opt/cpm /data && \
    chmod -R g=u /opt/cpm /data

VOLUME ["/data", "/conf"]
EXPOSE 3000

RUN chmod g=u /etc/passwd
ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
