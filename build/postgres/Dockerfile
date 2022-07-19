ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
ARG BASE_IMAGE_NAME
FROM ${PREFIX}/${BASE_IMAGE_NAME}:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG PG_FULL
ARG BASEOS
ARG DFSET
ARG PACKAGER

# ===== Early lines ordered for leveraging cache, reorder carefully =====
ARG PG_MAJOR
# Needed due to lack of environment substitution trick on ADD
ARG PG_LBL

RUN ${PACKAGER} -y install --nodocs \
	--disablerepo=crunchypg* \
	--enablerepo="crunchypg${PG_LBL}" \
	postgresql${PG_LBL} \
 && ${PACKAGER} -y clean all

# Preserving PGVERSION out of paranoia
ENV PGROOT="/usr/pgsql-${PG_MAJOR}" PGVERSION="${PG_MAJOR}"

ARG PATRONI_VER
ARG BACKREST_VER

# Separate yum run matching postgres-ha image, leverages cached layer
RUN if [ "$DFSET" = "centos" ] ; then \
        ${PACKAGER} -y install --nodocs \
        	--setopt=skip_missing_names_on_install=False \
        	openssh-clients \
        	openssh-server \
        	pgaudit${PG_MAJOR//.} \
        	pgaudit${PG_MAJOR//.}_set_user \
        	pg_partman_${PG_MAJOR//.} \
        	pg_cron_${PG_MAJOR//.} \
        	crunchy-backrest-${BACKREST_VER} \
        	postgresql${PG_MAJOR//.}-contrib \
        	postgresql${PG_MAJOR//.}-server \
        	postgresql${PG_MAJOR//.}-plpython* \
        	pgnodemx${PG_MAJOR//.} \
        	$( printf '11\n'${PG_MAJOR} | sort -VC && echo postgresql${PG_MAJOR}-llvmjit ) \
        	psmisc \
        	python3-pip \
        	python3-psutil \
        	python3-psycopg2 \
        	rsync \
        	$( printf '11\n'${PG_MAJOR} | sort -VC && echo timescaledb_${PG_MAJOR} ) \
        	wal2json_${PG_MAJOR//.} \
        	file \
        	gettext \
        	hostname \
        	procps-ng \
        	pgaudit_analyze \
        	unzip \
        	bzip2 \
        	lz4 \
			krb5-workstation \
			orafce_${PG_MAJOR//.} \
        && ${PACKAGER} -y clean all ; \
else \
        ${PACKAGER} -y install --nodocs \
		--enablerepo="epel" \
		openssh-clients \
		openssh-server \
		pgaudit${PG_MAJOR//.} \
		pgaudit${PG_MAJOR//.}_set_user \
		pg_partman_${PG_MAJOR//.} \
		pg_cron_${PG_MAJOR//.} \
		crunchy-backrest-${BACKREST_VER} \
		postgresql${PG_MAJOR//.}-contrib \
		postgresql${PG_MAJOR//.}-server \
		postgresql${PG_MAJOR//.}-plpython* \
		pgnodemx${PG_MAJOR//.} \
		$( printf '11\n'${PG_MAJOR} | sort -VC && echo postgresql${PG_MAJOR}-llvmjit ) \
		psmisc \
		python3-pip \
		python3-psutil \
		python3-psycopg2 \
		rsync \
		$( printf '11\n'${PG_MAJOR} | sort -VC && echo timescaledb_${PG_MAJOR} ) \
		wal2json_${PG_MAJOR//.} \
		file \
		unzip \
		tar \
		bzip2 \
		lz4 \
		krb5-workstation \
		orafce_${PG_MAJOR//.} \
	&& ${PACKAGER} -y install --nodocs \
		--setopt=tsflags='' \
		--enablerepo="epel" \
		pgaudit_analyze \
	&& ${PACKAGER} -y clean all --enablerepo="epel" ; \
fi

# install patroni for Kube
RUN pip3 install --upgrade python-dateutil \
	&& pip3 install patroni[kubernetes]=="${PATRONI_VER}"

ENV PATH="${PGROOT}/bin:${PATH}"

LABEL name="postgres" \
	summary="Crunchy PostgreSQL ${PG_FULL}" \
	description="Postgres ready for production: high availability, disaster recovery, monitoring, security, and performance. Works with PGO, the open source Postgres Operator from Crunchy Data." \
	io.k8s.description="Crunchy PostgreSQL is ready for production: the trusted open source distribution of PostgreSQL. Works with PGO, the open source Postgres Operator from Crunchy Data." \
	io.k8s.display-name="Crunchy PostgreSQL" \
	io.openshift.tags="postgresql,postgres,postgis,sql,nosql,database,ha,crunchy" \
	postgresql.version.major="${PG_MAJOR}" \
	postgresql.version="${PG_FULL}"

# set up crunchy directory
RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf /pgdata /pgwal /pgconf /backrestrepo

RUN chown -R postgres:postgres /opt/crunchy /var/lib/pgsql \
		/pgdata /pgwal /pgconf /backrestrepo &&  \
	chmod -R g=u /opt/crunchy /var/lib/pgsql \
		/pgdata /pgwal /pgconf /backrestrepo

# open up the postgres port
EXPOSE 5432

ADD bin/postgres_common /opt/crunchy/bin
ADD bin/common /opt/crunchy/bin
ADD conf/postgres_common /opt/crunchy/conf
ADD tools/pgmonitor/postgres_exporter/common /opt/crunchy/bin/modules/pgexporter
ADD tools/pgmonitor/postgres_exporter/linux /opt/crunchy/bin/modules/pgexporter

RUN mkdir /.ssh && chown 26:0 /.ssh && chmod g+rwx /.ssh && rm -f /run/nologin

# remove the default spool directory so that pgBackRest does not attempt to look there when
# performing a restore (pgBackRest will not have permissions to access to this dir in all envs)
RUN rm -rf /var/spool/pgbackrest

# add volumes to allow override of pg_hba.conf and postgresql.conf
# add volumes to allow storage of postgres WAL segment files
# add volumes to locate WAL files to recover with
# add volumes for pgbackrest to write to
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgdata", "/pgwal", "/pgconf", "/backrestrepo", "/sshd"]

# Defines a unique directory name that will be utilized by the nss_wrapper in the UID script
ENV NSS_WRAPPER_SUBDIR="postgres"

ENTRYPOINT ["/opt/crunchy/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/crunchy/bin/start.sh"]
