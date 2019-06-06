FROM $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/postgres-gis" \
	vendor="crunchy data" \
	PostgresVersion="9.6" \
	PostgresFullVersion="9.6.13" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Includes PostGIS extensions on top of crunchy-postgres" \
        description="An identical image of crunchy-postgres with the extra PostGIS and pgrouting packages added for users that require PostGIS." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="postgres-gis container" \
        io.k8s.display-name="Crunchy postgres-gis container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

USER 0

COPY conf/atomic/postgres-gis/help.1 /help.1
COPY conf/atomic/postgres-gis/help.md /help.md

RUN yum -y install --enablerepo=rhel-7-server-optional-rpms \
    R-core libRmath texinfo-tex texlive-epsf \
    postgis23_96 postgis23_96-client pgrouting_96 plr96 \
 && yum -y clean all

# open up the postgres port
EXPOSE 5432

ADD bin/postgres-gis /opt/cpm/bin

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
