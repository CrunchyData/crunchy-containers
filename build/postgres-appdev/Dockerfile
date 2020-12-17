ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR

# Needed due to lack of environment substitution trick on ADD
ARG PG_LBL

# Crunchy Postgres repo GPG Keys
# Both keys are added to support building all PG versions
# of this container. PG 11+ requires RPM-GPG-KEY-crunchydata
# PG 9.5, 9.6 and 10 require CRUNCHY-GPG-KEY.public on RHEL machines
ADD conf/*KEY* /

# Add any available Crunchy PG repo files
ADD conf/crunchypg${PG_LBL}.repo /etc/yum.repos.d/
# Import both keys to support all required repos
RUN rpm --import RPM-GPG-KEY-crunchydata*

RUN ${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		--disablerepo=crunchypg* \
		--enablerepo="crunchypg${PG_LBL}" \
		postgresql${PG_LBL} \
	&& ${PACKAGER} -y clean all

LABEL name="postgres-appdev" \
	summary="A PostgreSQL image that makes life easier for application developers. NOT FOR PRODUCTION USE" \
	description="A container image that contains all the extensions application developers probably want with extra ease of use" \
	io.k8s.description="postgres-appdev container" \
	io.k8s.display-name="Crunchy Data postgres-appdev container" \
	io.openshift.tags="postgresql,postgres,database,crunchy"

RUN ${PACKAGER} -y install \
	--setopt=skip_missing_names_on_install=False \
	libRmath \
	openssl\
	pgrouting25_${PG_MAJOR//.} \
	plr${PG_MAJOR//.} \
	postgis25_${PG_MAJOR//.} \
	postgis25_${PG_MAJOR//.}-client \
	postgresql${PG_MAJOR//.}-contrib \
	postgresql${PG_MAJOR//.}-plpython* \
	postgresql${PG_MAJOR//.}-server \
	pgnodemx${PG_MAJOR//.} \
	R-core \
	rsync \
	&& ${PACKAGER} -y clean all

ENV PGROOT="/usr/pgsql-${PG_MAJOR}"

RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf /pgdata /pgconf

RUN chown -R postgres:postgres /opt/crunchy /var/lib/pgsql \
	/pgdata /pgconf && \
	chmod -R g=u /opt/crunchy /var/lib/pgsql \
	/pgdata /pgconf

# open up the postgres port
EXPOSE 5432

ADD bin/postgres_common/postgres /opt/crunchy/bin
ADD bin/postgres-gis /opt/crunchy/bin
ADD bin/common /opt/crunchy/bin
# We load appdev scripts last so they overwrite the earlier ones
ADD bin/postgres-appdev /opt/crunchy/bin
ADD conf/postgres_common/postgres /opt/crunchy/conf
####### TODO If we put in PGAdmin need to put the conf here as well

ADD tools/pgmonitor/exporter/postgres /opt/crunchy/bin/modules/pgexporter

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

RUN mkdir /.ssh && chown 26:0 /.ssh && chmod g+rwx /.ssh

# add volumes to allow override of pg_hba.conf and postgresql.conf
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgconf", "/pgdata"]

ENTRYPOINT ["/opt/crunchy/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/crunchy/bin/start.sh"]
