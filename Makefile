ifndef CCPROOT
	export CCPROOT=$(GOPATH)/src/github.com/crunchydata/crunchy-containers
endif

.PHONY:	all versiontest

# Default target
all: pgimages extras

# Build images that use postgres
pgimages: commands backup backrestrestore pgbasebackuprestore collect pgadmin4 pgbadger pgbench pgbouncer pgdump pgpool pgrestore postgres postgres-gis upgrade

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
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.backrest-restore.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-backrest-restore:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)


backup:	versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.backup.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG)  $(CCP_IMAGE_PREFIX)/crunchy-backup:$(CCP_IMAGE_TAG)

pgbasebackuprestore:	versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.pgbasebackup-restore.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG)  $(CCP_IMAGE_PREFIX)/crunchy-pgbasebackup-restore:$(CCP_IMAGE_TAG)
collect: versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.collect.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-collect:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

grafana: versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.grafana.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-grafana:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgadmin4: versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgadmin4.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgadmin4:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgbadger: versiontest
	docker build -t $(CCP_IMAGE_PREFIX)/badgerserver:build -f $(CCP_BASEOS)/Dockerfile.badgerserver.$(CCP_BASEOS) .
	docker create --name extract $(CCP_IMAGE_PREFIX)/badgerserver:build
	docker cp extract:/go/src/github.com/crunchydata/crunchy-containers/badgerserver ./bin/pgbadger/badgerserver
	docker rm -f extract
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbadger.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgbadger:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgbench: versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbench.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgbench:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgbouncer: versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbouncer.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgbouncer:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgdump: versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgdump.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION) $(CCP_IMAGE_PREFIX)/crunchy-pgdump:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgpool:	versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgpool.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgpool:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgrestore: versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgrestore.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-pgrestore:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

postgres: versiontest commands
	cp $(GOBIN)/pgc bin/postgres
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

postgres-gis: versiontest commands
	cp $(GOBIN)/pgc bin/postgres
	expenv -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS) > $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS).tmp
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS).tmp -t $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres-gis:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)
	rm -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS).tmp

postgres-appdev: versiontest commands
	cp $(GOBIN)/pgc bin/postgres
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-appdev.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-postgres-appdev:latest

prometheus:	versiontest
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.prometheus.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-prometheus:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

sample-app: versiontest
	docker build -t $(CCP_IMAGE_PREFIX)/sample-app-build:build -f $(CCP_BASEOS)/Dockerfile.sample-app-build.$(CCP_BASEOS) .
	docker create --name extract $(CCP_IMAGE_PREFIX)/sample-app-build:build
	docker cp extract:/go/src/github.com/crunchydata/sample-app/sample-app ./bin/sample-app
	docker rm -f extract
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.sample-app.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-sample-app:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-sample-app:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-sample-app:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-sample-app:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-sample-app:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

scheduler: versiontest
	docker build -t $(CCP_IMAGE_PREFIX)/scheduler-build:build -f $(CCP_BASEOS)/Dockerfile.scheduler-build.$(CCP_BASEOS) .
	docker create --name extract $(CCP_IMAGE_PREFIX)/scheduler-build:build
	docker cp extract:/go/src/github.com/crunchydata/crunchy-containers/scheduler ./bin/scheduler
	docker rm -f extract
	sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/Dockerfile.scheduler.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_IMAGE_TAG) $(CCPROOT)
	sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_IMAGE_TAG)
	docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-scheduler:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

upgrade: versiontest
	if [[ '$(CCP_PGVERSION)' != '9.5' ]]; then \
		sudo --preserve-env buildah bud $(SQUASH) -f $(CCPROOT)/$(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.upgrade.$(CCP_BASEOS) -t $(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) $(CCPROOT) ;\
		sudo --preserve-env buildah push $(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) docker-daemon:$(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) ;\
		docker tag docker.io/$(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) $(CCP_IMAGE_PREFIX)/crunchy-upgrade:$(CCP_IMAGE_TAG) ;\
	fi

#=================
# Utility targets
#=================
push:
	./bin/push-to-dockerhub.sh

-include Makefile.build
