ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-postgres:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR
ARG POSTGIS_LBL

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
		libRmath \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		plr${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client \
		postgresql${PG_MAJOR//.}-plperl \
		perl \
		R-core \
	&& ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "centos8" ] ; then \
	${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		--enablerepo="PowerTools" \
		libRmath \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		plr${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client \
		postgresql${PG_MAJOR//.}-plperl \
		perl \
		R-core \
	&& ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "rhel7" ] ; then \
	${PACKAGER} -y install \
		--enablerepo="epel,rhel-7-server-optional-rpms" \
		--setopt=skip_missing_names_on_install=False \
		libRmath \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		plr${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client \
		postgresql${PG_MAJOR//.}-plperl \
		perl \
		R-core \
		texinfo-tex \
		texlive-epsf \
	&& ${PACKAGER} -y clean all --enablerepo="epel,rhel-7-server-optional-rpms" ; \
fi

RUN if [ "$BASEOS" = "ubi7" ] ; then \
	${PACKAGER} -y install \
		--enablerepo="epel,rhel-7-server-optional-rpms" \
		--setopt=skip_missing_names_on_install=False \
		libRmath \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		plr${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client \
		postgresql${PG_MAJOR//.}-plperl \
		perl \
		R-core \
		texinfo-tex \
		texlive-epsf \
	&& ${PACKAGER} -y clean all --enablerepo="epel,rhel-7-server-optional-rpms" ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y --enablerepo="epel,codeready-builder-for-rhel-8-x86_64-rpms" install libaec libdap armadillo \
	&& ${PACKAGER} -y install \
		--enablerepo="epel" \
		--setopt=skip_missing_names_on_install=False \
		libRmath \
		hdf5 \
		openldap \
		pgrouting${POSTGIS_LBL}_${PG_MAJOR//.} \
		plr${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.} \
		postgis${POSTGIS_LBL}_${PG_MAJOR//.}-client \
		postgresql${PG_MAJOR//.}-plperl \
		perl \
		R-core \
		texlive-epsf \
	&& ${PACKAGER} -y clean all --enablerepo="epel,codeready-builder-for-rhel-8-x86_64-rpms" ; \
fi

# open up the postgres port
EXPOSE 5432

ADD bin/postgres-gis /opt/crunchy/bin/postgres

ENTRYPOINT ["/opt/crunchy/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/crunchy/bin/start.sh"]
