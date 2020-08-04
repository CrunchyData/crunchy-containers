ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER

ARG PG_MAJOR

LABEL name="pgbasebackup-restore" \
	summary="Restores a database using a pg_basebackup backup" \
	description="Restores a database into a specified PGDATA directory using a pg_basebackup backup." \
	io.k8s.description="pg_basebackup restore container" \
	io.k8s.display-name="pg_basebackup restore container" \
	io.openshift.tags="postgresql,postgres,pgbackrest,backup,database,crunchy"

RUN ${PACKAGER} -y install \
        --setopt=skip_missing_names_on_install=False \
        rsync \
        && ${PACKAGER} -y clean all

RUN groupadd postgres -g 26 && \
	useradd postgres -g 26 -u 26

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata

RUN chown -R postgres:postgres /opt/cpm /pgdata

ADD bin/pgbasebackup_restore /opt/cpm/bin
ADD bin/common /opt/cpm/bin

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/backup","/pgdata"]

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
