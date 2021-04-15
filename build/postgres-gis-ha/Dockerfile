ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
ARG POSTGIS_VER
FROM ${PREFIX}/crunchy-postgres-gis:${BASEOS}-${PG_FULL}-${POSTGIS_VER}-${BASEVER}
# crunchy-postgres image runs as USER 26, switch back to install packages
USER 0

# ===== Early lines ordered for leveraging cache, reorder carefully =====
# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG PG_FULL
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR

# Preserving PGVERSION out of paranoia
ENV PGROOT="/usr/pgsql-${PG_MAJOR}" PGVERSION="${PG_MAJOR}"

# ===== Steps unique to this image after here =====
ARG PATRONI_VER

LABEL name="postgres-gis-ha" \
	summary="Includes PostGIS extensions on top of crunchy-postgres-ha" \
	description="An identical image of crunchy-postgres with the extra PostGIS packages added for users that require PostGIS, optimized for high-availability." \
	io.k8s.description="PostGIS enabled PostgreSQL container" \
	io.k8s.display-name="Crunchy PostGIS HA" \
	io.openshift.tags="postgresql,postgres,postgis,spatial,geospatial,gis,map,database,ha,crunchy"

RUN if [ "$DFSET" = "centos" ] ; then \
	${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		python3-pip \
		python3-psutil \
		python3-psycopg2 \
	&& ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "rhel7" ] ; then \
	${PACKAGER} -y install \
		--enablerepo="epel,rhel-7-server-optional-rpms" \
		--setopt=skip_missing_names_on_install=False \
		python3-pip \
		python3-psutil \
		python3-psycopg2 \
	&& ${PACKAGER} -y clean all --enablerepo="epel,rhel-7-server-optional-rpms" ; \
fi

RUN if [ "$BASEOS" = "ubi7" ] ; then \
	${PACKAGER} -y install \
		--enablerepo="epel,rhel-7-server-optional-rpms" \
		--setopt=skip_missing_names_on_install=False \
		python3-pip \
		python3-psutil \
		python3-psycopg2 \
	&& ${PACKAGER} -y clean all --enablerepo="epel,rhel-7-server-optional-rpms" ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install \
		--enablerepo="epel" \
		python3-pip \
		python3-psutil \
		python3-psycopg2 \
	&& ${PACKAGER} -y clean all --enablerepo="epel" ; \
fi

# install patroni for Kube
RUN pip3 install --upgrade python-dateutil \
	&& pip3 install patroni[kubernetes]=="${PATRONI_VER}"

ENV PATH="${PGROOT}/bin:${PATH}"

RUN mkdir -p /tablespaces

# Adjust ownership for the folders to be the "postgres" user and allow the group
# permissions to match the user ones EXCEPT for the /tablespaces folder, which
# will only have permissions on the user
RUN chown -R postgres:postgres /tablespaces && \
	chmod -R g=u /tablespaces

# open up the postgres port
EXPOSE 5432

ADD bin/postgres-ha /opt/crunchy/bin/postgres-ha
ADD bin/postgres-gis-ha /opt/crunchy/bin/postgres-ha
ADD conf/postgres-ha /opt/crunchy/conf/postgres-ha

ADD yq /opt/crunchy/bin
RUN chmod +x /opt/crunchy/bin/yq

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgdata", "/pgwal", "/pgconf", "/backrestrepo", "/sshd"]

ENTRYPOINT ["/opt/crunchy/bin/postgres-ha/bootstrap-postgres-ha.sh"]

USER 26

CMD ["/usr/local/bin/patroni"]
