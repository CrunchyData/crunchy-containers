ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-pg-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG PG_FULL
ARG DFSET
ARG PACKAGER

ARG PG_MAJOR

LABEL name="pgbench" \
	summary="pgBench ${PG_FULL}" \
	description="pgbench is a simple program for running benchmark tests on PostgreSQL. It runs the same sequence of SQL commands over and over, possibly in multiple concurrent database sessions, and then calculates the average transaction rate (transactions per second)." \
	io.k8s.description="pgbench container" \
	io.k8s.display-name="pgbench container" \
	io.openshift.tags="postgresql,postgres,benchmark,database,crunchy"

RUN ${PACKAGER} -y install \
        --setopt=skip_missing_names_on_install=False \
        rsync \
        && ${PACKAGER} -y clean all

# Preserving PGVERSION out of paranoia
ENV PGROOT="/usr/pgsql-${PG_MAJOR}" PGVERSION="${PG_MAJOR}"

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf

RUN chown -R 26:0 /opt/cpm && \
	chmod -R g=u /opt/cpm

ADD bin/pgbench /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgbench /opt/cpm/conf

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgconf"]

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
