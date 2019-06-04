FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/pgbench" \
        vendor="crunchy data" \
	PostgresVersion="9.5" \
	PostgresFullVersion="9.5.17" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
    	summary="pgBench 9.5.16 (PGDG) on a RHEL7 base image" \
        description="pgbench is a simple program for running benchmark tests on PostgreSQL. It runs the same sequence of SQL commands over and over, possibly in multiple concurrent database sessions, and then calculates the average transaction rate (transactions per second)." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="pgbench container" \
        io.k8s.display-name="Crunchy pgbench container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/pgbench/help.1 /help.1
COPY conf/atomic/pgbench/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="9.5"
ENV PGROOT="/usr/pgsql-${PGVERSION}"

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg95.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
 && yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum -y install bind-utils \
    gettext \
    hostname \
    procps-ng \
    rsync \
 && yum -y reinstall glibc-common \
 && yum -y install postgresql95 \
 && yum -y clean all

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf

RUN chown -R 26:0 /opt/cpm \
 && chmod -R g=u /opt/cpm

ADD bin/pgbench /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgbench /opt/cpm/conf

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

VOLUME ["/pgconf"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
