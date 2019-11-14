ifndef CCPROOT
	export CCPROOT=$(GOPATH)/src/github.com/crunchydata/crunchy-containers
endif

# Default values if not already set
CCP_PG_VERSION?=11
CCP_PG_FULLVERSION?=11.6
CCP_PATRONI_VERSION?=1.5.6
CCP_BACKREST_VERSION?=2.18

ifeq ($(CCP_PGVERSION),9.5)
	CCP_PGAUDIT = _95
endif
ifeq ($(CCP_PGVERSION),9.6)
	CCP_PGAUDIT = 11_96
endif
ifeq ($(CCP_PGVERSION),10)
	CCP_PGAUDIT = 12_10
endif
ifeq ($(CCP_PGVERSION),11)
	CCP_PGAUDIT = 13_11
endif
ifeq ($(CCP_PGVERSION),12)
	CCP_PGAUDIT = 14_12
endif

.PHONY:	all versiontest setpgaudit

# Default target
all: pgimages extras

# Build images that use postgres
pgimages: commands backup backrestrestore pgbasebackuprestore collect pgadmin4 pgbadger pgbench pgbouncer pgdump pgpool pgrestore postgres postgres-ha postgres-gis postgres-gis-ha upgrade crunchyadm

# Build non-postgres images
extras: grafana prometheus scheduler

versiontest:
ifndef CCP_BASEOS
	$(error CCP_BASEOS is not defined)
endif
ifndef CCP_PGVERSION
	$(error CCP_PGVERSION is not defined)
endif
ifndef CCP_PG_FULLVERSION
	$(error CCP_PG_FULLVERSION is not defined)
endif
ifndef CCP_VERSION
	$(error CCP_VERSION is not defined)
endif
ifndef CCP_PATRONI_VERSION
	$(error CCP_PATRONI_VERSION is not defined)
endif
ifndef CCP_BACKREST_VERSION
	$(error CCP_BACKREST_VERSION is not defined)
endif

setup:
	$(CCPROOT)/bin/install-deps.sh

docbuild:
	cd $CCPROOT && ./generate-docs.sh

#=============================================
# Targets that generate commands (alphabetized)
#=============================================

commands: pgc

pgc:
	cd $(CCPROOT)/commands/pgc && go build pgc.go && mv pgc $(GOBIN)/pgc


#=============================================
# Targets that generate images (alphabetized)
#=============================================

backrestrestore: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.backrest-restore.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)


backup:	versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.backup.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG)  $(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG)

pgbasebackuprestore:	versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.pgbasebackup-restore.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG)  $(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG)
collect: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.collect.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

grafana: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.grafana.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgadmin4: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgadmin4.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgbadger: versiontest
	docker build -t $(CCP_IMAGE_PREFIX)/badgerserver:build -f $(CCP_BASEOS)/Dockerfile.badgerserver.$(CCP_BASEOS) .
	docker create --name extract $(CCP_IMAGE_PREFIX)/badgerserver:build
	docker cp extract:/go/src/github.com/crunchydata/crunchy-containers/badgerserver ./bin/pgbadger/badgerserver
	docker rm -f extract
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbadger.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgbench: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbench.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgbouncer: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbouncer.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgdump: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgdump.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION) $(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgpool:	versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgpool.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgrestore: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgrestore.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

postgres: versiontest commands
	cp $(GOBIN)/pgc bin/postgres
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

postgres-ha: versiontest
	sudo --preserve-env buildah bud \
	--build-arg ccp_pg_version=$(CCP_PGVERSION) \
	--build-arg ccp_pg_full_version=$(CCP_PG_FULLVERSION) \
    --build-arg ccp_patroni_version=$(CCP_PATRONI_VERSION) \
	--build-arg ccp_backrest_version=$(CCP_BACKREST_VERSION) \
	--build-arg ccp_pgaudit_version=$(CCP_PGAUDIT) \
	--layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.postgres-ha.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres-ha:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

postgres-gis: versiontest commands
	cp $(GOBIN)/pgc bin/postgres
	expenv -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS) > $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS).tmp
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS).tmp -t $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)
	rm -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS).tmp

postgres-gis-ha: versiontest commands
	cp $(GOBIN)/pgc bin/postgres
	sudo --preserve-env buildah bud \
	--build-arg ccp_pg_version=$(CCP_PGVERSION) \
	--build-arg ccp_pg_full_version=$(CCP_PG_FULLVERSION) \
	--build-arg ccp_image_prefix=$(CCP_IMAGE_PREFIX) \
	--build-arg ccp_image_tag=$(CCP_IMAGE_TAG) \
	--layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.postgres-gis-ha.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis-ha:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)


postgres-appdev: versiontest commands
	cp $(GOBIN)/pgc bin/postgres
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-appdev.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:latest

prometheus:	versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.prometheus.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

scheduler: versiontest
	docker build -t $(CCP_IMAGE_PREFIX)/scheduler-build:build -f $(CCP_BASEOS)/Dockerfile.scheduler-build.$(CCP_BASEOS) .
	docker create --name extract $(CCP_IMAGE_PREFIX)/scheduler-build:build
	docker cp extract:/go/src/github.com/crunchydata/crunchy-containers/scheduler ./bin/scheduler
	docker rm -f extract
	sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.scheduler.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

upgrade: versiontest
	if [[ '$(CCP_PGVERSION)' != '9.5' ]]; then \
		sudo --preserve-env buildah bud --layers $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.upgrade.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) $(CCPROOT) ;\
		sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) ;\
		docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) ;\
	fi

crunchyadm: versiontest
	sudo --preserve-env buildah bud --layers $(SQUASH) \
	    --build-arg ccp_pgversion=$(CCP_PGVERSION) \
		-f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.admin.$(CCP_BASEOS) \
		-t $(CCP_IMAGE_PREFIX)/crunchy-admin:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-admin:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-admin:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-admin:$(CCP_IMAGE_TAG)  $(CCP_IMAGE_PREFIX)/crunchy-admin:$(CCP_IMAGE_TAG)

#=================
# Utility targets
#=================
push:
	./bin/push-to-dockerhub.sh

-include Makefile.build
