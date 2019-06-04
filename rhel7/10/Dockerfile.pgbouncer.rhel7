FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/pgbouncer" \
	vendor="crunchy data" \
	PostgresVersion="10" \
	PostgresFullVersion="10.8" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Lightweight connection pooler for crunchy-postgres" \
        description="The aim of crunchy-pgbouncer is to lower the performance impact of opening new connections to PostgreSQL; clients connect through this service. It offers session, transaction and statement pooling." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="pgbouncer container" \
        io.k8s.display-name="Crunchy pgbouncer container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/pgbouncer/help.1 /help.1
COPY conf/atomic/pgbouncer/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="10"

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg10.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum -y install epel-release \
 && yum -y install \
      gettext \
      hostname  \
      pgbouncer \
      postgresql10 \
      procps-ng \
 && yum clean all -y

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgconf

ADD bin/pgbouncer /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgbouncer /opt/cpm/conf

RUN chown -R 2:0 /opt/cpm /pgconf && \
    chmod -R g=u /opt/cpm /pgconf

EXPOSE 6432

VOLUME ["/pgconf"]

RUN chmod g=u /etc/passwd
ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
