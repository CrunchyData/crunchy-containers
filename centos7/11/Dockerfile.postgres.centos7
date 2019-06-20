FROM centos:7

LABEL name="crunchydata/postgres" \
        vendor="crunchy data" \
	PostgresVersion="11" \
	PostgresFullVersion="11.4" \
	Version="7.6" \
	Release="2.4.1" \
        url="https://crunchydata.com" \
	summary="PostgreSQL 11.4 (PGDG) on a Centos7 base image" \
        description="Allows multiple deployment methods for PostgreSQL, including basic single primary, streaming replication with synchronous and asynchronous replicas, and stateful sets. Includes utilities for Auditing (pgaudit), statement tracking, and Backup / Restore (pgbackrest, pg_basebackup)." \
        io.k8s.description="postgres container" \
        io.k8s.display-name="Crunchy postgres container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

ENV PGVERSION="11" PGDG_REPO="pgdg-redhat-repo-latest.noarch.rpm" PGDG_REPO_DISABLE="pgdg10,pgdg96,pgdg95,pgdg94" \
    BACKREST_VERSION="2.13"

RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/${PGVERSION}/redhat/rhel-7-x86_64/${PGDG_REPO}

RUN yum -y update \
 && yum -y install epel-release \
 && yum -y update glibc-common \
 && yum -y install bind-utils \
    gettext \
    hostname \
    procps-ng  \
    rsync \
    psmisc openssh-server openssh-clients \
 && yum -y install --disablerepo="${PGDG_REPO_DISABLE}" \
    postgresql11-server postgresql11-contrib postgresql11 \
    pgaudit13_11 \
    pgbackrest-"${BACKREST_VERSION}" \
 && yum -y clean all

ENV PGROOT="/usr/pgsql-${PGVERSION}"

# add path settings for postgres user
# bash_profile is loaded in login, but not with exec
# bashrc to set permissions in OCP when using exec
# HOME is / in OCP
ADD conf/.bash_profile /var/lib/pgsql/
ADD conf/.bashrc /var/lib/pgsql
ADD conf/.bash_profile /
ADD conf/.bashrc /

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /pgwal /pgconf /recover /backrestrepo

RUN chown -R postgres:postgres /opt/cpm /var/lib/pgsql \
    /pgdata /pgwal /pgconf /recover /backrestrepo &&  \
    chmod -R g=u /opt/cpm /var/lib/pgsql \
    /pgdata /pgwal /pgconf /recover /backrestrepo

# add volumes to allow override of pg_hba.conf and postgresql.conf
# add volumes to offer a restore feature
# add volumes to allow storage of postgres WAL segment files
# add volumes to locate WAL files to recover with
# add volumes for pgbackrest to write to

VOLUME ["/sshd", "/pgconf", "/pgdata", "/pgwal", "/recover", "/backrestrepo"]

# open up the postgres port
EXPOSE 5432

ADD bin/postgres /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/postgres /opt/cpm/conf
ADD tools/pgmonitor/exporter/postgres /opt/cpm/bin/modules

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

RUN mkdir /.ssh && chown 26:0 /.ssh && chmod g+rwx /.ssh

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
