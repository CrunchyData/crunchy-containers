ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-pg-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR

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
	pgrouting_${PG_MAJOR//.} \
	plr${PG_MAJOR//.} \
	postgis25_${PG_MAJOR//.} \
	postgis25_${PG_MAJOR//.}-client \
	postgresql${PG_MAJOR//.}-contrib \
	postgresql${PG_MAJOR//.}-plpython* \
	postgresql${PG_MAJOR//.}-server \
	R-core \
	rsync \
	&& ${PACKAGER} -y clean all

ENV PGROOT="/usr/pgsql-${PG_MAJOR}"

# add path settings for postgres user
# bash_profile is loaded in login, but not with exec
# bashrc to set permissions in OCP when using exec
# HOME is / in OCP
ADD conf/.bash_profile /var/lib/pgsql/
ADD conf/.bashrc /var/lib/pgsql
ADD conf/.bash_profile /
ADD conf/.bashrc /

#RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /pgwal /pgconf /backup /recover /backrestrepo
RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /pgconf

RUN chown -R postgres:postgres /opt/cpm /var/lib/pgsql \
	/pgdata /pgconf && \
	chmod -R g=u /opt/cpm /var/lib/pgsql \
	/pgdata /pgconf

# open up the postgres port
EXPOSE 5432

ADD bin/postgres /opt/cpm/bin
ADD bin/postgres-gis /opt/cpm/bin
ADD bin/common /opt/cpm/bin
# We load appdev scripts last so they overwrite the earlier ones
ADD bin/postgres-appdev /opt/cpm/bin
ADD conf/postgres /opt/cpm/conf
####### TODO If we put in PGAdmin need to put the conf here as well

ADD tools/pgmonitor/exporter/postgres /opt/cpm/bin/modules/pgexporter

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

RUN mkdir /.ssh && chown 26:0 /.ssh && chmod g+rwx /.ssh

# add volumes to allow override of pg_hba.conf and postgresql.conf
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgconf", "/pgdata"]

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
