ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-postgres-gis-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR
ARG POSTGIS_LBL
ARG POSTGIS_FULL_VER

LABEL name="postgres-gis" \
	summary="Includes PostGIS extensions on top of crunchy-postgres" \
	description="An identical image of crunchy-postgres with the extra PostGIS packages added for users that require PostGIS." \
	io.k8s.description="postgres-gis container" \
	io.k8s.display-name="Crunchy PostGIS" \
	io.openshift.tags="postgresql,postgres,postgis,spatial,geospatial,gis,map,database,ha,crunchy"

USER 0

RUN if [ "$BASEOS" = "centos7" ] ; then \
	${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-${POSTGIS_FULL_VER} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client-${POSTGIS_FULL_VER} \
		postgresql${PG_MAJOR//.}-plperl \
		postgresql${PG_MAJOR//.}-pltcl \
	&& ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "centos8" ] ; then \
	${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		--enablerepo="powertools" \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-${POSTGIS_FULL_VER} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client-${POSTGIS_FULL_VER} \
		postgresql${PG_MAJOR//.}-plperl \
		postgresql${PG_MAJOR//.}-pltcl \
	&& ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "ubi7" ] ; then \
	${PACKAGER} -y install \
		--enablerepo="epel,rhel-7-server-optional-rpms" \
		--setopt=skip_missing_names_on_install=False \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-${POSTGIS_FULL_VER} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client-${POSTGIS_FULL_VER} \
		postgresql${PG_MAJOR//.}-plperl \
		postgresql${PG_MAJOR//.}-pltcl \
	&& ${PACKAGER} -y clean all --enablerepo="epel,rhel-7-server-optional-rpms" ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install \
		--enablerepo="epel" \
		--enablerepo="codeready-builder-for-rhel-8-x86_64-rpms" \
		libaec libdap armadillo \
	&& ${PACKAGER} -y install \
		--enablerepo="epel" \
		--enablerepo="codeready-builder-for-rhel-8-x86_64-rpms" \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-${POSTGIS_FULL_VER} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client-${POSTGIS_FULL_VER} \
		postgresql${PG_MAJOR//.}-plperl \
		postgresql${PG_MAJOR//.}-pltcl \
	&& ${PACKAGER} -y clean all \
		--enablerepo="epel" \
		--enablerepo="codeready-builder-for-rhel-8-x86_64-rpms" ; \
fi

# open up the postgres port
EXPOSE 5432

ADD bin/postgres-gis /opt/crunchy/bin/postgres

ENTRYPOINT ["/opt/crunchy/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/crunchy/bin/start.sh"]
