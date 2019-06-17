FROM $CCP_IMAGE_PREFIX/crunchy-postgres:$CCP_IMAGE_TAG

LABEL name="crunchydata/postgres-gis" \
        vendor="crunchy data" \
	PostgresVersion="11" \
	PostgresFullVersion="11.3" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Includes PostGIS extensions on top of crunchy-postgres" \
        description="An identical image of crunchy-postgres with the extra PostGIS packages added for users that require PostGIS." \
        io.k8s.description="postgres-gis container" \
        io.k8s.display-name="Crunchy postgres-gis container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

USER 0

RUN yum -y install \
    R-core libRmath plr11 \
    postgis24_11 postgis24_11-client \
 && yum -y clean all

# open up the postgres port
EXPOSE 5432

ADD bin/postgres-gis /opt/cpm/bin

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
