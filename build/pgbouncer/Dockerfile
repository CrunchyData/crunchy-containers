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

LABEL name="pgbouncer" \
	summary="Lightweight connection pooler for crunchy-postgres" \
	description="The aim of crunchy-pgbouncer is to lower the performance impact of opening new connections to PostgreSQL; clients connect through this service. It offers session, transaction and statement pooling." \
	io.k8s.description="pgBouncer" \
	io.k8s.display-name="pgBouncer" \
	io.openshift.tags="postgresql,postgres,pooling,pgbouncer,database,crunchy"

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
	--disablerepo="epel" \
	--setopt=skip_missing_names_on_install=False \
	pgbouncer \
	&& ${PACKAGER} -y clean all

# Preserving PGVERSION out of paranoia
ENV PGVERSION="${PG_MAJOR}"

RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf /pgconf

ADD bin/pgbouncer /opt/crunchy/bin
ADD bin/common /opt/crunchy/bin
ADD conf/pgbouncer /opt/crunchy/conf

RUN chown -R 2:0 /opt/crunchy /pgconf && \
	chmod -R g=u /opt/crunchy /pgconf

EXPOSE 6432

RUN chmod g=u /etc/passwd

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgconf"]

ENTRYPOINT ["opt/crunchy/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/crunchy/bin/start.sh"]
