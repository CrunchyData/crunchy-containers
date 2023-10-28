ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG PACKAGER
ARG BACKREST_VER
ARG BASEOS

LABEL name="pgbackrest" \
	summary="Crunchy pgBackRest ${BACKREST_VER}" \
	description="The Crunchy pgBackRest container that supports pgBackRest backups, restores, and repo functionality modes." \
	io.k8s.description="pgBackRest" \
	io.k8s.display-name="Crunchy pgBackRest" \
	io.openshift.tags="postgresql,postgres,pgbackrest,backup,database,crunchy"

# Run postgres install in separate transaction ahead of backrest for postgres user
RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install --nodocs \
		openssh-clients \
		openssh-server \
		shadow-utils \
		tar \
		bzip2 \
		lz4 \
		crunchy-backrest-${BACKREST_VER} \
		&& ${PACKAGER} -y clean all ; \
else \
	${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		openssh-clients \
		openssh-server \
		bzip2 \
		lz4 \
		crunchy-backrest-${BACKREST_VER} \
		&& ${PACKAGER} -y clean all ; \
fi


# add postgres user and group
RUN groupadd postgres -g 26 && useradd postgres -u 26 -g 26

# set up crunchy directory
RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf /pgdata /backrestrepo \
	/var/log/pgbackrest

# add pgbackrest-restore files
COPY bin/pgbackrest-restore /opt/crunchy/bin
COPY conf/pgbackrest-restore /opt/crunchy/conf

# add pgbackrest files
COPY bin/pgbackrest /opt/crunchy/bin

# add pgbackrest-common files
COPY bin/common /opt/crunchy/bin
COPY bin/pgbackrest-common /opt/crunchy/bin

# set user and group ownership
RUN chown -R postgres:postgres /opt/crunchy  \
	/backrestrepo /var/log/pgbackrest /pgdata

# add the pgbackrest-repo specific files and directories, and
# set the appropriate permissions and ownership
COPY bin/pgbackrest-repo /usr/local/bin
RUN chmod +x /usr/local/bin/pgbackrest-repo.sh /usr/local/bin/archive-push-s3.sh \
		/usr/local/bin/archive-push-gcs.sh \
	&& mkdir -p /etc/pgbackrest \
	&& chown -R postgres:postgres /etc/pgbackrest

RUN chmod -R g=u /etc/pgbackrest \
	&& rm -f /run/nologin

RUN mkdir /.ssh && chown postgres:postgres /.ssh && chmod o+rwx /.ssh

# remove the default spool directory so that pgBackRest does not attempt to look there when
# performing a restore (pgBackRest will not have permissions to access to this dir in all envs)
RUN rm -rf /var/spool/pgbackrest

# create necessary volumes for all modes
#
# /sshd and /backrestrepo required for the pgBackRest repo mode
# /pgdata required for the pgbackrest-restore mode
#
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/sshd", "/pgdata", "/backrestrepo"]

USER 26

# Defines a unique directory name that will be utilized by the nss_wrapper in the UID script
ENV NSS_WRAPPER_SUBDIR="pgbackrest"

ENTRYPOINT ["/opt/crunchy/bin/uid_postgres.sh"]

CMD ["/opt/crunchy/bin/start.sh"]
