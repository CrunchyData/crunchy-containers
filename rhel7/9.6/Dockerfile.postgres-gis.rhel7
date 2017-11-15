FROM registry.access.redhat.com/rhel

MAINTAINER Crunchy Data <support@crunchydata.com>

LABEL name="crunchydata/postgres-gis" \
        vendor="crunchy data" \
      	PostgresVersion="9.6" \
      	PostgresFullVersion="9.6.6" \
        version="7.3" \
        release="1.7.0" \
        #build-date="2017-05-11" \
        url="https://crunchydata.com" \
        summary="Includes PostGIS extensions on top of crunchy-postgres" \
        description="An identical image of crunchy-postgres with the extra PostGIS and pgrouting packages added for users that require PostGIS." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="postgres-gis container" \
        io.k8s.display-name="Crunchy postgres-gis container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY docs/postgres-gis/help.1 /help.1
COPY docs/postgres-gis/help.md /help.md
COPY docs/licenses /licenses

ENV PGVERSION="9.6"

# if you ever need to install package docs inside the container, uncomment
#RUN sed -i '/nodocs/d' /etc/yum.conf

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg96.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
 && yum -y update && yum --enablerepo=epel --enablerepo="rhel-7-server-optional-rpms" -y install bind-utils \
	gettext \
	hostname \
	R-core libRmath texinfo-tex texlive-epsf \
	nss_wrapper \
	openssh-clients \
	procps-ng \
 	rsync \
        postgresql96 postgresql96-contrib postgresql96-server \
	pgaudit96 pgaudit96_set_user \
	crunchy-backrest plr96 \
	postgis2_96 postgis2_96-client pgrouting_96 \
 && yum -y reinstall glibc-common \
 && yum -y --setopt=tsflags='' install pgaudit_analyze \
 && yum -y clean all

ENV PGROOT="/usr/pgsql-${PGVERSION}"

# add path settings for postgres user
ADD conf/.bash_profile /var/lib/pgsql/

# set up cpm directory
RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /pgwal /pgconf /backup /recover /backrestrepo

RUN chown -R postgres:postgres /opt/cpm /var/lib/pgsql \
	/pgdata /pgwal /pgconf /backup /recover /backrestrepo

# add volumes to allow override of pg_hba.conf and postgresql.conf
# add volumes to allow backup of postgres files
# add volumes to offer a restore feature
# add volumes to allow storage of postgres WAL segment files
# add volumes to locate WAL files to recover with
# volume for pgbackrest to write to

VOLUME /pgconf /pgdata /pgwal \
  /backup /recover /backrestrepo

# open up the postgres port
EXPOSE 5432

ADD bin/postgres /opt/cpm/bin
ADD bin/postgres-gis /opt/cpm/bin
ADD conf/postgres /opt/cpm/conf

USER 26

CMD ["/opt/cpm/bin/start.sh"]
