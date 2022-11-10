ifndef CCPROOT
	export CCPROOT=$(GOPATH)/src/github.com/crunchydata/crunchy-containers
endif

# Default values if not already set
CCP_BASEOS ?= centos7
CCP_PGVERSION ?= 12
CCP_PG_FULLVERSION ?= 12.13
CCP_PATRONI_VERSION ?= 2.0.2
CCP_BACKREST_VERSION ?= 2.29
CCP_VERSION ?= 4.5.9
CCP_POSTGIS_VERSION ?= 3.0
CCP_PGADMIN_VERSION ?= 4.20
CCP_PGBADGER_GO_VERSION ?= 1.17.7
PACKAGER ?= yum

# Valid values: buildah (default), docker
IMGBUILDER ?= buildah
# Determines whether or not images should be pushed to the local docker daemon when building with
# a tool other than docker (e.g. when building with buildah)
IMG_PUSH_TO_DOCKER_DAEMON ?= true
# Defines the sudo command that should be prepended to various build commands when rootless builds are
# not enabled
IMGCMDSUDO=
ifneq ("$(IMG_ROOTLESS_BUILD)", "true")
	IMGCMDSUDO=sudo --preserve-env
endif
IMGCMDSTEM=$(IMGCMDSUDO) buildah bud --layers $(SQUASH)
DFSET=$(CCP_BASEOS)
DOCKERBASEREGISTRY=registry.access.redhat.com/

# Default the buildah format to docker to ensure it is possible to pull the images from a docker
# repository using docker (otherwise the images may not be recognized)
export BUILDAH_FORMAT ?= docker

# Allows simplification of IMGBUILDER switching
ifeq ("$(IMGBUILDER)","docker")
	IMGCMDSTEM=docker build
endif

# Allows consolidation of ubi/rhel Dockerfile sets
ifeq ("$(CCP_BASEOS)", "rhel7")
        DFSET=rhel
endif

ifeq ("$(CCP_BASEOS)", "ubi7")
        DFSET=rhel
endif

ifeq ("$(CCP_BASEOS)", "ubi8")
        DFSET=rhel
	PACKAGER=dnf
endif

ifeq ("$(CCP_BASEOS)", "centos7")
        DFSET=centos
	DOCKERBASEREGISTRY=centos:
endif

ifeq ("$(CCP_BASEOS)", "centos8")
        DFSET=centos
	PACKAGER=dnf
	DOCKERBASEREGISTRY=centos:
endif

.PHONY:	all pg-independent-images pgimages

# Default target
all: cc-pg-base-image pgimages pg-independent-images

# Build images that either don't have a PG dependency or using the latest PG version is all that is needed
pg-independent-images: backup pgadmin4 pgbadger pgbasebackuprestore pgbench pgbouncer pgpool

# Build images that require a specific postgres version - ordered for potential concurrent benefits
pgimages: postgres postgres-ha backrestrestore crunchyadm postgres-gis postgres-gis-ha pgdump pgrestore upgrade

#===========================================
# Targets generating pg-based images
#===========================================

backrestrestore: backrest-restore-pgimg-$(IMGBUILDER)
backup:	backup-pgimg-$(IMGBUILDER)
crunchyadm: admin-pgimg-$(IMGBUILDER)
pgadmin4: pgadmin4-pgimg-$(IMGBUILDER)
pgbadger: pgbadger-pgimg-$(IMGBUILDER)
pgbench: pgbench-pgimg-$(IMGBUILDER)
pgbouncer: pgbouncer-pgimg-$(IMGBUILDER)
pgdump: pgdump-pgimg-$(IMGBUILDER)
pgpool: pgpool-pgimg-$(IMGBUILDER)
pgrestore: pgrestore-pgimg-$(IMGBUILDER)
postgres: postgres-pgimg-$(IMGBUILDER)
postgres-ha: postgres-ha-pgimg-$(IMGBUILDER)
postgres-gis: postgres-gis-pgimg-$(IMGBUILDER)
postgres-gis-ha: postgres-gis-ha-pgimg-$(IMGBUILDER)


#===========================================
# Targets generating non-pg-based images
#===========================================

pgbasebackuprestore: pgbasebackup-restore-img-$(IMGBUILDER)


#===========================================
# Pattern-based image generation targets
#===========================================

$(CCPROOT)/build/%/Dockerfile:
	$(error No Dockerfile found for $* naming pattern: [$@])

# ----- Base Image -----
ccbase-image: ccbase-image-$(IMGBUILDER)

ccbase-image-build: $(CCPROOT)/build/base/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/base/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-base:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg RELVER=$(CCP_VERSION) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		--build-arg DOCKERBASEREGISTRY=$(DOCKERBASEREGISTRY) \
		$(CCPROOT)

ccbase-image-buildah: ccbase-image-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-base:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-base:$(CCP_IMAGE_TAG)
endif

ccbase-image-docker: ccbase-image-build

# ----- PG Base Image -----
cc-pg-base-image: cc-pg-base-image-$(IMGBUILDER)

cc-pg-base-image-build: ccbase-image $(CCPROOT)/build/pg-base/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/pg-base/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-pg-base:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_LBL=$(subst .,,$(CCP_PGVERSION)) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

cc-pg-base-image-buildah: cc-pg-base-image-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pg-base:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pg-base:$(CCP_IMAGE_TAG)
endif

cc-pg-base-image-docker: cc-pg-base-image-build

# ----- Special case pg-based image (postgres) -----
# Special case args: BACKREST_VER
postgres-pgimg-build: cc-pg-base-image commands $(CCPROOT)/build/postgres/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/postgres/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg BACKREST_VER=$(CCP_BACKREST_VERSION) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

postgres-pgimg-buildah: postgres-pgimg-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG)
endif

postgres-pgimg-docker: postgres-pgimg-build

# ----- Special case pg-based image (postgres-gis) -----
# Special case args: POSTGIS_LBL
postgres-gis-pgimg-build: postgres commands $(CCPROOT)/build/postgres-gis/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/postgres-gis/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_POSTGIS_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg POSTGIS_LBL=$(subst .,,$(CCP_POSTGIS_VERSION)) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

postgres-gis-pgimg-buildah: postgres-gis-pgimg-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_POSTGIS_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_POSTGIS_IMAGE_TAG)
endif

postgres-gis-pgimg-docker: postgres-gis-pgimg-build

# ----- Special case pg-based image (postgres-ha) -----
# Special case args: BACKREST_VER, PATRONI_VER
postgres-ha-pgimg-build: cc-pg-base-image commands $(CCPROOT)/build/postgres-ha/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/postgres-ha/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg BACKREST_VER=$(CCP_BACKREST_VERSION) \
		--build-arg PATRONI_VER=$(CCP_PATRONI_VERSION) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

postgres-ha-pgimg-buildah: postgres-ha-pgimg-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG)
endif

postgres-ha-pgimg-docker: postgres-ha-pgimg-build

# ----- Special case pg-based image (postgres-gis-ha) -----
# Special case args: POSTGIS_LBL
postgres-gis-ha-pgimg-build: postgres-ha commands $(CCPROOT)/build/postgres-gis-ha/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/postgres-gis-ha/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_POSTGIS_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg POSTGIS_LBL=$(subst .,,$(CCP_POSTGIS_VERSION)) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		--layers=false \
		$(CCPROOT)

postgres-gis-ha-pgimg-buildah: postgres-gis-ha-pgimg-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_POSTGIS_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_POSTGIS_IMAGE_TAG)
endif

postgres-gis-ha-pgimg-docker: postgres-gis-ha-pgimg-build

# ----- Special case pg-based image (backrest-restore) -----
# Special case args: BACKREST_VER
backrest-restore-pgimg-build: cc-pg-base-image $(CCPROOT)/build/backrest-restore/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/backrest-restore/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg BACKREST_VER=$(CCP_BACKREST_VERSION) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

backrest-restore-pgimg-buildah: backrest-restore-pgimg-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG)
endif

backrest-restore-pgimg-docker: backrest-restore-pgimg-build

# ----- All other pg-based images ----
%-pgimg-build: cc-pg-base-image $(CCPROOT)/build/%/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/$*/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-$*:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

%-pgimg-buildah: %-pgimg-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-$*:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-$*:$(CCP_IMAGE_TAG)
endif

%-pgimg-docker: %-pgimg-build ;

# Special case args: CCP_PGADMIN_VERSION
pgadmin4-pgimg-build: cc-pg-base-image $(CCPROOT)/build/pgadmin4/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/pgadmin4/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg PGADMIN_VER=$(CCP_PGADMIN_VERSION) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

pgadmin4-pgimg-buildah: pgadmin4-pgimg-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG)
endif

pgadmin4-pgimg-docker: pgadmin-pgimg-build

# ----- Extra images -----
%-img-build: ccbase-image $(CCPROOT)/build/%/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/$*/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-$*:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

%-img-buildah: %-img-build ;
# only push to docker daemon if variable PGO_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-$*:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-$*:$(CCP_IMAGE_TAG)
endif

%-img-docker: %-img-build ;

# ----- Upgrade Images -----
upgrade: upgrade-$(CCP_PGVERSION)

upgrade-%: upgrade-pgimg-$(IMGBUILDER) ;

upgrade-9.5: # Do nothing but log to avoid erroring out on missing Dockerfile
	$(info Upgrade build skipped for 9.5)

# Special case args: PGBADGER_GO_VER
pgbadger-pgimg-build: cc-pg-base-image $(CCPROOT)/build/pgbadger/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/pgbadger/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		--build-arg PGBADGER_GO_VER=$(CCP_PGBADGER_GO_VERSION) \
		$(CCPROOT)

pgbadger-pgimg-buildah: pgbadger-pgimg-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG)
endif

pgbadger-pgimg-docker: pgbadger-pgimg-build

#=================
# Utility targets
#=================
setup:
	$(CCPROOT)/bin/install-deps.sh

docbuild:
	cd $(CCPROOT) && ./generate-docs.sh

push:
	./bin/push-to-dockerhub.sh

-include Makefile.build
