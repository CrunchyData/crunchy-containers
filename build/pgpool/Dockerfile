ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-pg-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER

ARG PG_MAJOR

LABEL name="pgpool" \
	summary="Contains the pgpool utility as a PostgreSQL-aware load balancer" \
	description="Offers a smart load balancer in front of a Postgres cluster, sending writes only to the primary and reads to the replica(s). This allows an application to only have a single connection point when interacting with a Postgres cluster." \
	io.k8s.description="pgpool II" \
	io.k8s.display-name="pgpool II" \
	io.openshift.tags="postgresql,postgres,pgpool,database,crunchy"

RUN ${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		pgpool-II-${PG_MAJOR//.} \
		pgpool-II-${PG_MAJOR//.}-extensions \
	&& ${PACKAGER} -y clean all

# Preserving PGVERSION out of paranoia
ENV PGVERSION="${PG_MAJOR}"

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf

ADD bin/pgpool /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgpool /opt/cpm/conf

RUN ln -sf /opt/cpm/conf/pool_hba.conf /etc/pgpool-II-${PG_MAJOR//.}/pool_hba.conf \
	&& ln -sf /opt/cpm/conf/pgpool/pool_passwd /etc/pgpool-II-${PG_MAJOR//.}/pool_passwd

RUN chgrp -R 0 /opt/cpm && \
	chmod -R g=u /opt/cpm


# open up the postgres port
EXPOSE 5432

RUN chmod g=u /etc/passwd

# add volumes to allow override of pgpool config files
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgconf"]

ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/startpgpool.sh"]
