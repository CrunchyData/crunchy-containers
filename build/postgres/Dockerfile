ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG PG_FULL
ARG BASEOS
ARG DFSET
ARG PACKAGER

# ===== Early lines ordered for leveraging cache, reorder carefully =====
ARG PG_MAJOR
# Needed due to lack of environment substitution trick on ADD
ARG PG_LBL

LABEL postgresql.version.major="${PG_MAJOR}" \
	postgresql.version="${PG_FULL}"

# Crunchy Postgres repo GPG Keys
# Both keys are added to support building all PG versions
# of this container. PG 11+ requires RPM-GPG-KEY-crunchydata
# PG 9.5, 9.6 and 10 require CRUNCHY-GPG-KEY.public on RHEL machines
ADD conf/*KEY* /

# Add any available Crunchy PG repo files
ADD conf/crunchypg${PG_LBL}.repo /etc/yum.repos.d/
# Import both keys to support all required repos
RUN rpm --import RPM-GPG-KEY-crunchydata*
RUN if [ "$DFSET" = "rhel" ] ; then rpm --import CRUNCHY-GPG-KEY.public ; fi

RUN if [ "$BASEOS" = "centos8" ] ; then \
	${PACKAGER} -qy module disable postgresql ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -qy module disable postgresql ; \
fi

RUN ${PACKAGER} -y install \
	--setopt=skip_missing_names_on_install=False \
	--disablerepo=crunchypg* \
	--enablerepo="crunchypg${PG_LBL}" \
	postgresql${PG_LBL} \
 && ${PACKAGER} -y clean all

# Preserving PGVERSION out of paranoia
ENV PGROOT="/usr/pgsql-${PG_MAJOR}" PGVERSION="${PG_MAJOR}"

ARG BACKREST_VER

# Separate yum run matching postgres-ha image, leverages cached layer
RUN if [ "$DFSET" = "centos" ] ; then \
        ${PACKAGER} -y install \
        	--setopt=skip_missing_names_on_install=False \
        	openssh-clients \
        	openssh-server \
        	pgaudit${PG_MAJOR//.} \
        	pgaudit${PG_MAJOR//.}_set_user \
        	crunchy-backrest-${BACKREST_VER} \
        	postgresql${PG_MAJOR//.}-contrib \
        	postgresql${PG_MAJOR//.}-server \
        	postgresql${PG_MAJOR//.}-plpython* \
        	pgnodemx${PG_MAJOR//.} \
        	$( printf '11\n'${PG_MAJOR} | sort -VC && echo postgresql${PG_MAJOR}-llvmjit ) \
        	psmisc \
        	rsync \
        	wal2json${PG_MAJOR//.} \
        	file \
        	gettext \
        	hostname \
        	procps-ng \
        	pgaudit_analyze \
        	unzip \
        && ${PACKAGER} -y clean all ; \
else \
        ${PACKAGER} -y install \
		--enablerepo="epel" \
		--setopt=skip_missing_names_on_install=False \
		openssh-clients \
		openssh-server \
		pgaudit${PG_MAJOR//.} \
		pgaudit${PG_MAJOR//.}_set_user \
		crunchy-backrest-${BACKREST_VER} \
		postgresql${PG_MAJOR//.}-contrib \
		postgresql${PG_MAJOR//.}-server \
		postgresql${PG_MAJOR//.}-plpython* \
		pgnodemx${PG_MAJOR//.} \
		$( printf '11\n'${PG_MAJOR} | sort -VC && echo postgresql${PG_MAJOR}-llvmjit ) \
		psmisc \
		rsync \
		wal2json${PG_MAJOR//.} \
		file \
		unzip \
	&& ${PACKAGER} -y install \
		--setopt=tsflags='' \
		--enablerepo="epel" \
		pgaudit_analyze \
	&& ${PACKAGER} -y clean all --enablerepo="epel" ; \
fi

# ===== Steps unique to this image after here =====
LABEL name="postgres" \
	summary="PostgreSQL ${PG_FULL}" \
	description="Allows multiple deployment methods for PostgreSQL, including basic single primary, streaming replication with synchronous and asynchronous replicas. Includes utilities for Auditing (pgaudit), statement tracking, and Backup / Restore (pgbackrest, pg_basebackup)." \
	io.k8s.description="Crunchy PostgreSQL is the trusted open source distribution of PostgreSQL" \
	io.k8s.display-name="Crunchy PostgreSQL" \
	io.openshift.tags="postgresql,postgres,sql,nosql,database,crunchy"

# add path settings for postgres user
# bash_profile is loaded in login, but not with exec
# bashrc to set permissions in OCP when using exec
# HOME is / in OCP
ADD conf/.bash_profile /var/lib/pgsql/
ADD conf/.bashrc /var/lib/pgsql
ADD conf/.bash_profile /
ADD conf/.bashrc /

# set up crunchy directory
RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf /pgdata /pgwal /pgconf /recover /backrestrepo

RUN chown -R postgres:postgres /opt/crunchy /var/lib/pgsql \
		/pgdata /pgwal /pgconf /recover /backrestrepo &&  \
	chmod -R g=u /opt/crunchy /var/lib/pgsql \
		/pgdata /pgwal /pgconf /recover /backrestrepo

# open up the postgres port
EXPOSE 5432

ADD bin/postgres_common /opt/crunchy/bin
ADD bin/common /opt/crunchy/bin
ADD conf/postgres_common /opt/crunchy/conf
ADD tools/pgmonitor/exporter/postgres /opt/crunchy/bin/modules/pgexporter

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

RUN mkdir /.ssh && chown 26:0 /.ssh && chmod g+rwx /.ssh && rm -f /run/nologin

# add volumes to allow override of pg_hba.conf and postgresql.conf
# add volumes to offer a restore feature
# add volumes to allow storage of postgres WAL segment files
# add volumes to locate WAL files to recover with
# add volumes for pgbackrest to write to
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/sshd", "/pgconf", "/pgdata", "/pgwal", "/recover", "/backrestrepo"]

ENTRYPOINT ["/opt/crunchy/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/crunchy/bin/start.sh"]
