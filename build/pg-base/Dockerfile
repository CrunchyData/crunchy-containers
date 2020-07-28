ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
ARG DFSET
ARG PACKAGER
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

ARG PG_MAJOR
# Needed due to lack of environment substitution trick on ADD
ARG PG_LBL

LABEL postgresql.version.major="${PG_MAJOR}" \
	postgresql.version="${PG_FULL}"

# Crunchy Postgres repo GPG Keys
# Both keys are added to support building all PG versions
# of this container. PG 11+ requires RPM-GPG-KEY-crunchydata
# PG 9.5, 9.6 and 10 require CRUNCHY-GPG-KEY.public
ADD conf/RPM-GPG-KEY-crunchydata*  /
ADD if [ "$DFSET" = "rhel" ] ; then conf/CRUNCHY-GPG-KEY.public  / ; fi

# Add any available Crunchy PG repo files
ADD conf/crunchypg${PG_LBL}.repo /etc/yum.repos.d/
# Import both keys to support all required repos
RUN rpm --import RPM-GPG-KEY-crunchydata*
RUN if [ "$DFSET" = "rhel" ] ; then rpm --import CRUNCHY-GPG-KEY.public ; fi

RUN ${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		--disablerepo=crunchypg* \
		--enablerepo="crunchypg${PG_LBL}" \
		postgresql${PG_LBL} \
	&& ${PACKAGER} -y clean all
