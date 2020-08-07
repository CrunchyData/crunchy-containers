ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-pg-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR
ARG BACKREST_VER

LABEL name="backrest-restore" \
	summary="Allows full, delta & point-in-time-recovery restore capabilities with pgBackRest." \
	description="Allows full, delta & point-in-time-recovery restore capabilities with pgBackRest. Capable of mounting the /backrestrepo for access to pgbackrest archives, while allowing for the configuration of pgBackRest using applicable pgBackRest environment variables." \
	io.k8s.description="pgBackRest Restore" \
	io.k8s.display-name="Crunchy pgBackRest Restore" \
	io.openshift.tags="postgresql,postgres,pgbackrest,backup,database,crunchy"

# Run postgres install in separate transaction ahead of backrest for postgres user
RUN ${PACKAGER} -y install  \
		--setopt=skip_missing_names_on_install=False \
		--enablerepo="epel" \
		nss_wrapper \
		postgresql${PG_MAJOR//.}-server \
	&& ${PACKAGER} -y install crunchy-backrest-${BACKREST_VER} \
	&& ${PACKAGER} -y clean all --enablerepo="epel"

# Preserving PGVERSION out of paranoia
ENV	PGROOT="/usr/pgsql-${PG_MAJOR}" PGVERSION="${PG_MAJOR}"

# add path settings for postgres user
ADD conf/.bash_profile /var/lib/pgsql/

# set up cpm directory
RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /backrestrepo \
	/var/lib/pgsql /var/log/pgbackrest

RUN chown -R postgres:postgres /opt/cpm  \
	/pgdata /backrestrepo \
	/var/lib/pgsql /var/log/pgbackrest

ADD bin/backrest_restore /opt/cpm/bin

ADD conf/backrest_restore /opt/cpm/conf

# volume backrestrepo for pgbackrest to restore from and log
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME /pgdata /backrestrepo

USER 26
CMD ["/opt/cpm/bin/start.sh"]
