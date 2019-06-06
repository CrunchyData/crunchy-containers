FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/pgbadger" \
        vendor="crunchy data" \
	PostgresVersion="10" \
	PostgresFullVersion="10.8" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="HTTP wrapper around the PGBadger PostgreSQL utility" \
        description="Has an HTTP REST interface. You GET http://host:10000/api/badgergenerate, and it will generate a pgbadger report on a database container's log files." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="pgbadger container" \
        io.k8s.display-name="Crunchy pgbadger container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/pgbadger/help.1 /help.1
COPY conf/atomic/pgbadger/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="10"

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg10.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum -y install epel-release \
 && yum -y install --enablerepo="rhel-7-server-optional-rpms" \
      gettext \
      hostname \
      pgbadger \
 && yum clean all -y

RUN groupadd -g 26 postgres && useradd -g 26 -u 26 postgres

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /report

ADD conf/pgbadger /opt/cpm/conf
ADD bin/common /opt/cpm/bin
ADD bin/pgbadger /opt/cpm/bin

RUN chown -R postgres:postgres /opt/cpm /report /bin && \
        chmod -R g=u /opt/cpm /report /bin

# pgbadger port
EXPOSE 10000

VOLUME ["/pgdata", "/report"]

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

ENTRYPOINT ["opt/cpm/bin/uid_postgres.sh"]


USER 26

CMD ["/opt/cpm/bin/start-pgbadger.sh"]
