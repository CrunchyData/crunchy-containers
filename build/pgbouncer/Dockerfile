ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-pg-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER

ARG PG_MAJOR

LABEL name="pgbouncer" \
	summary="Lightweight connection pooler for crunchy-postgres" \
	description="The aim of crunchy-pgbouncer is to lower the performance impact of opening new connections to PostgreSQL; clients connect through this service. It offers session, transaction and statement pooling." \
	io.k8s.description="pgBouncer" \
	io.k8s.display-name="pgBouncer" \
	io.openshift.tags="postgresql,postgres,pooling,pgbouncer,database,crunchy"

RUN ${PACKAGER} -y install \
	--setopt=skip_missing_names_on_install=False \
	pgbouncer \
	&& ${PACKAGER} -y clean all

# Preserving PGVERSION out of paranoia
ENV PGVERSION="${PG_MAJOR}"

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgconf

ADD bin/pgbouncer /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgbouncer /opt/cpm/conf

RUN chown -R 2:0 /opt/cpm /pgconf && \
	chmod -R g=u /opt/cpm /pgconf

EXPOSE 6432

RUN chmod g=u /etc/passwd

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgconf"]

ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
