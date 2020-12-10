ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER
ARG BASEOS
ARG PG_MAJOR
ARG PG_LBL

LABEL name="pgpool" \
	summary="Contains the pgpool utility as a PostgreSQL-aware load balancer" \
	description="Offers a smart load balancer in front of a Postgres cluster, sending writes only to the primary and reads to the replica(s). This allows an application to only have a single connection point when interacting with a Postgres cluster." \
	io.k8s.description="pgpool II" \
	io.k8s.display-name="pgpool II" \
	io.openshift.tags="postgresql,postgres,pgpool,database,crunchy"

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
		pgpool-II-${PG_MAJOR//.} \
		pgpool-II-${PG_MAJOR//.}-extensions \
	&& ${PACKAGER} -y clean all

# Preserving PGVERSION out of paranoia
ENV PGVERSION="${PG_MAJOR}"

RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf

ADD bin/pgpool /opt/crunchy/bin
ADD bin/common /opt/crunchy/bin
ADD conf/pgpool /opt/crunchy/conf

RUN ln -sf /opt/crunchy/conf/pool_hba.conf /etc/pgpool-II-${PG_MAJOR//.}/pool_hba.conf \
	&& ln -sf /opt/crunchy/conf/pgpool/pool_passwd /etc/pgpool-II-${PG_MAJOR//.}/pool_passwd

RUN chgrp -R 0 /opt/crunchy && \
	chmod -R g=u /opt/crunchy


# open up the postgres port
EXPOSE 5432

RUN chmod g=u /etc/passwd

# add volumes to allow override of pgpool config files
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgconf"]

ENTRYPOINT ["opt/crunchy/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/crunchy/bin/startpgpool.sh"]
