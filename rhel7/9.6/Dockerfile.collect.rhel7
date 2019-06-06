FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/collect" \
        vendor="crunchy data" \
	PostgresVersion="9.6" \
	PostgresFullVersion="9.6.13" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Provides metrics for crunchy-postgres" \
        description="Run with crunchy-postgres, crunchy-collect reads the Postgres data directory and has a SQL interface to a database to allow for metrics collection. Used in conjunction with crunchy-prometheus and crunchy-grafana." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="collect container" \
        io.k8s.display-name="Crunchy collect container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/collect/help.1 /help.1
COPY conf/atomic/collect/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="9.6"

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg96.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Install postgres client tools and libraries
RUN yum install -y epel-release \
  && yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
  && yum -y install \
    gettext \
    postgresql96 \
    postgresql96-libs \
    hostname \
  && yum -y clean all

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf

ADD postgres_exporter.tar.gz /opt/cpm/bin
ADD tools/pgmonitor/exporter/postgres /opt/cpm/conf
ADD bin/collect /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/collect /opt/cpm/conf

RUN chgrp -R 0 /opt/cpm/bin /opt/cpm/conf && \
    chmod -R g=u /opt/cpm/bin/ opt/cpm/conf

VOLUME ["/conf"]

# postgres_exporter
EXPOSE 9187

RUN chmod g=u /etc/passwd

ENTRYPOINT ["/opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
