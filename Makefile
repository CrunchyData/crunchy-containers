ifndef CCPROOT
	export CCPROOT=$(GOPATH)/src/github.com/crunchydata/crunchy-containers
endif

# Default values if not already set
CCP_BASEOS ?= ubi8
CCP_PGVERSION ?= 13
CCP_PG_FULLVERSION ?= 13.8
CCP_PATRONI_VERSION ?= 2.0.2
CCP_BACKREST_VERSION ?= 2.31
CCP_VERSION ?= 4.6.8
CCP_POSTGIS_VERSION ?= 3.0
CCP_PGADMIN_VERSION ?= 4.20
CCP_PGBADGER_GO_VERSION ?= 1.17.7
PACKAGER ?= yum

# Valid values: buildah (default), docker
IMGBUILDER ?= buildah
# Determines whether or not images should be pushed to the local docker daemon when building with
# a tool other than docker (e.g. when building with buildah)
IMG_PUSH_TO_DOCKER_DAEMON ?= true
# The utility to use when pushing/pulling to and from an image repo (e.g. docker or buildah)
IMG_PUSHER_PULLER ?= docker
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

.PHONY:	all license pgbackrest-images pg-independent-images pgimages

# list of image names, helpful in pushing
images = crunchy-postgres \
	crunchy-postgres-ha \
	crunchy-upgrade \
	crunchy-pgbackrest \
	crunchy-pgbackrest-repo \
	crunchy-pgadmin4 \
	crunchy-pgbadger \
	crunchy-pgbouncer \
	crunchy-pgpool

# Default target
all: pgimages pg-independent-images pgbackrest-images

# Build images that either don't have a PG dependency or using the latest PG version is all that is needed
pg-independent-images: pgadmin4 pgbadger pgbouncer pgpool

# Build images that require a specific postgres version - ordered for potential concurrent benefits
pgimages: postgres postgres-ha postgres-gis postgres-gis-ha upgrade

# Build images based on pgBackRest
pgbackrest-images: pgbackrest pgbackrest-repo

#===========================================
# Targets generating pg-based images
#===========================================

pgadmin4: pgadmin4-img-$(IMGBUILDER)
pgbackrest: pgbackrest-pgimg-$(IMGBUILDER)
pgbackrest-repo: pgbackrest-repo-pgimg-$(IMGBUILDER)
pgbadger: pgbadger-pgimg-$(IMGBUILDER)
pgbouncer: pgbouncer-img-$(IMGBUILDER)
pgpool: pgpool-img-$(IMGBUILDER)
postgres: postgres-pgimg-$(IMGBUILDER)
postgres-ha: postgres-ha-pgimg-$(IMGBUILDER)
postgres-gis: postgres-gis-pgimg-$(IMGBUILDER)
postgres-gis-ha: postgres-gis-ha-pgimg-$(IMGBUILDER)

#===========================================
# Pattern-based image generation targets
#===========================================

$(CCPROOT)/build/%/Dockerfile:
	$(error No Dockerfile found for $* naming pattern: [$@])

# ----- Base Image -----
ccbase-image: ccbase-image-$(IMGBUILDER)

ccbase-image-build: build-pgbackrest license $(CCPROOT)/build/base/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/base/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-base:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg RELVER=$(CCP_VERSION) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		--build-arg DOCKERBASEREGISTRY=$(DOCKERBASEREGISTRY) \
		--build-arg PG_LBL=${subst .,,$(CCP_PGVERSION)} \
		$(CCPROOT)

ccbase-image-buildah: ccbase-image-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-base:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-base:$(CCP_IMAGE_TAG)
endif

ccbase-image-docker: ccbase-image-build

# ----- Base Image Ext -----
ccbase-ext-image-build: ccbase-image $(CCPROOT)/build/base-ext/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/base-ext/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-base-ext:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PACKAGER=$(PACKAGER) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		$(CCPROOT)

ccbase-ext-image-buildah: ccbase-ext-image-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-base-ext:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-base-ext:$(CCP_IMAGE_TAG)
endif

ccbase-ext-image-docker: ccbase-ext-image-build

# ----- Special case pg-based image (postgres) -----
# Special case args: BACKREST_VER
postgres-pgimg-build: ccbase-image $(CCPROOT)/build/postgres/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/postgres/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_LBL=${subst .,,$(CCP_PGVERSION)} \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg BACKREST_VER=$(CCP_BACKREST_VERSION) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		--build-arg BASE_IMAGE_NAME=crunchy-base \
		$(CCPROOT)

postgres-pgimg-buildah: postgres-pgimg-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG)
endif

postgres-pgimg-docker: postgres-pgimg-build

# ----- Special case pg-based image (postgres-gis-base) -----
# Used as the base for the postgres-gis image.
postgres-gis-base-pgimg-build: ccbase-ext-image-build $(CCPROOT)/build/postgres/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/postgres/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-base:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_LBL=${subst .,,$(CCP_PGVERSION)} \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg BACKREST_VER=$(CCP_BACKREST_VERSION) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		--build-arg BASE_IMAGE_NAME=crunchy-base-ext \
		$(CCPROOT)

postgres-gis-base-pgimg-buildah: postgres-gis-base-pgimg-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-base:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-base:$(CCP_IMAGE_TAG)
endif

# ----- Special case pg-based image (postgres-gis) -----
# Special case args: POSTGIS_LBL
postgres-gis-pgimg-build: postgres-gis-base-pgimg-build $(CCPROOT)/build/postgres-gis/Dockerfile
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
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_POSTGIS_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_POSTGIS_IMAGE_TAG)
endif

postgres-gis-pgimg-docker: postgres-gis-pgimg-build

# ----- Special case pg-based image (postgres-ha) -----
# Special case args: BACKREST_VER, PATRONI_VER
postgres-ha-pgimg-build: postgres-pgimg-build $(CCPROOT)/build/postgres-ha/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/postgres-ha/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg PATRONI_VER=$(CCP_PATRONI_VERSION) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

postgres-ha-pgimg-buildah: postgres-ha-pgimg-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG)
endif

postgres-ha-pgimg-docker: postgres-ha-pgimg-build

# ----- Special case pg-based image (postgres-gis-ha) -----
# Special case args: PATRONI_VER
postgres-gis-ha-pgimg-build: postgres-gis-pgimg-build $(CCPROOT)/build/postgres-gis-ha/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/postgres-gis-ha/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_POSTGIS_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PATRONI_VER=$(CCP_PATRONI_VERSION) \
		--build-arg POSTGIS_VER=$(CCP_POSTGIS_VERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg DFSET=$(DFSET) \
		--build-arg PACKAGER=$(PACKAGER) \
		--layers=false \
		$(CCPROOT)

postgres-gis-ha-pgimg-buildah: postgres-gis-ha-pgimg-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_POSTGIS_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_POSTGIS_IMAGE_TAG)
endif

postgres-gis-ha-pgimg-docker: postgres-gis-ha-pgimg-build


# ----- Special case image (pgbackrest) -----

# build the needed binary
build-pgbackrest:
	go build -o bin/pgbackrest/pgbackrest ./cmd/pgbackrest

# Special case args: BACKREST_VER
pgbackrest-pgimg-build: ccbase-image build-pgbackrest $(CCPROOT)/build/pgbackrest/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/pgbackrest/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-pgbackrest:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PG_MAJOR=$(CCP_PGVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		--build-arg BACKREST_VER=$(CCP_BACKREST_VERSION) \
		--build-arg PACKAGER=$(PACKAGER) \
		$(CCPROOT)

pgbackrest-pgimg-buildah: pgbackrest-pgimg-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbackrest:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbackrest:$(CCP_IMAGE_TAG)
endif

pgbackrest-pgimg-docker: pgbackrest-pgimg-build


# ----- Special case image (pgbackrest-repo) -----

# Special case args: BACKREST_VER
pgbackrest-repo-pgimg-build: ccbase-image build-pgbackrest pgbackrest $(CCPROOT)/build/pgbackrest-repo/Dockerfile
	$(IMGCMDSTEM) \
		-f $(CCPROOT)/build/pgbackrest-repo/Dockerfile \
		-t $(CCP_IMAGE_PREFIX)/crunchy-pgbackrest-repo:$(CCP_IMAGE_TAG) \
		--build-arg BASEOS=$(CCP_BASEOS) \
		--build-arg BASEVER=$(CCP_VERSION) \
		--build-arg PG_FULL=$(CCP_PG_FULLVERSION) \
		--build-arg PREFIX=$(CCP_IMAGE_PREFIX) \
		$(CCPROOT)

pgbackrest-repo-pgimg-buildah: pgbackrest-repo-pgimg-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbackrest-repo:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbackrest-repo:$(CCP_IMAGE_TAG)
endif

pgbackrest-repo-pgimg-docker: pgbackrest-repo-pgimg-build

# Special case args: CCP_PGADMIN_VERSION
pgadmin4-img-build: ccbase-image $(CCPROOT)/build/pgadmin4/Dockerfile
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

pgadmin4-img-buildah: pgadmin4-img-build ;
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG)
endif

pgadmin4-img-docker: pgadmin-img-build

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
# only push to docker daemon if variable IMG_PUSH_TO_DOCKER_DAEMON is set to "true"
ifeq ("$(IMG_PUSH_TO_DOCKER_DAEMON)", "true")
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-$*:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-$*:$(CCP_IMAGE_TAG)
endif

%-img-docker: %-img-build ;

# ----- Upgrade Images -----
upgrade: upgrade-$(CCP_PGVERSION)

upgrade-%: upgrade-img-$(IMGBUILDER) ;

upgrade-9.5: # Do nothing but log to avoid erroring out on missing Dockerfile
	$(info Upgrade build skipped for 9.5)

# Special case args: PGBADGER_GO_VER
pgbadger-pgimg-build: ccbase-image $(CCPROOT)/build/pgbadger/Dockerfile
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

license:
	./bin/license_aggregator.sh

push: push-gis $(images:%=push-%) ;

push-gis:
	$(IMG_PUSHER_PULLER) push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_POSTGIS_IMAGE_TAG)
	$(IMG_PUSHER_PULLER) push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_POSTGIS_IMAGE_TAG)

push-%:
	$(IMG_PUSHER_PULLER) push $(CCP_IMAGE_PREFIX)/$*:$(CCP_IMAGE_TAG)

-include Makefile.build
