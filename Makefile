ifndef CCPROOT
	export CCPROOT=$(GOPATH)/src/github.com/crunchydata/crunchy-containers
endif

.PHONY:	all versiontest

# Default target
all:    backup backrestrestore collectserver dbaserver grafana pgadmin4 pgbadger pgbouncer pgdump pgpool postgres postgres-gis prometheus promgateway upgrade vac

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

gendeps:
	godep save \
	github.com/crunchydata/crunchy-containers/dba \
	github.com/crunchydata/crunchy-containers/collectapi \
	github.com/crunchydata/crunchy-containers/badger  \
	github.com/crunchydata/crunchy-containers/cct

docbuild:
	cd docs && ./build-docs.sh

#=============================================
# Targets that generate images (alphabetized)
#=============================================

backrestrestore: versiontest
	docker build -t crunchy-backrest-restore -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.backrest-restore.$(CCP_BASEOS) .
	docker tag crunchy-backrest-restore crunchydata/crunchy-backrest-restore:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

backup:	versiontest
	docker build -t crunchy-backup -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.backup.$(CCP_BASEOS) .
	docker tag crunchy-backup crunchydata/crunchy-backup:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

collectserver: versiontest
	cd collect && godep go install collectserver.go
	cp $(GOBIN)/collectserver bin/collect
	docker build -t crunchy-collect -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.collect.$(CCP_BASEOS) .
	docker tag crunchy-collect crunchydata/crunchy-collect:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

dbaserver:
	cp `which oc` bin/dba
	cp `which kubectl` bin/dba
	cd dba && godep go install dbaserver.go
	cp $(GOBIN)/dbaserver bin/dba
	docker build -t crunchy-dba -f $(CCP_BASEOS)/Dockerfile.dba.$(CCP_BASEOS) .
	docker tag crunchy-dba crunchydata/crunchy-dba:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

grafana: versiontest
	docker build -t crunchy-grafana -f $(CCP_BASEOS)/Dockerfile.grafana.$(CCP_BASEOS) .
	docker tag crunchy-grafana crunchydata/crunchy-grafana:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgadmin4: versiontest
	docker build -t crunchy-pgadmin4 -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgadmin4.$(CCP_BASEOS) .
	docker tag crunchy-pgadmin4 crunchydata/crunchy-pgadmin4:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgbadger: versiontest
	cd badger && godep go install badgerserver.go
	cp $(GOBIN)/badgerserver bin/pgbadger
	docker build -t crunchy-pgbadger -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbadger.$(CCP_BASEOS) .
	docker tag crunchy-pgbadger crunchydata/crunchy-pgbadger:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgbouncer: versiontest
	cp `which oc` bin/pgbouncer
	cp `which kubectl` bin/pgbouncer
	cd bounce && godep go install bounce.go
	cp $(GOBIN)/bounce bin/pgbouncer/
	docker build -t crunchy-pgbouncer -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbouncer.$(CCP_BASEOS) .
	docker tag crunchy-pgbouncer crunchydata/crunchy-pgbouncer:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgdump: versiontest
	docker build -t crunchy-dump -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgdump.$(CCP_BASEOS) .
	docker tag crunchy-dump crunchydata/crunchy-dump:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgpool:	versiontest
	docker build -t crunchy-pgpool -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgpool.$(CCP_BASEOS) .
	docker tag crunchy-pgpool crunchydata/crunchy-pgpool:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

pgsim:
	cd sim && make
	cp sim/build/crunchy-sim bin/crunchy-sim
	docker build -t crunchy-sim -f $(CCP_BASEOS)/Dockerfile.sim.$(CCP_BASEOS) .
	docker tag crunchy-sim crunchydata/crunchy-sim:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

postgres: versiontest
	cp `which kubectl` bin/postgres
	cp `which oc` bin/postgres
	docker build -t crunchy-postgres -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres.$(CCP_BASEOS) .
	docker tag crunchy-postgres crunchydata/crunchy-postgres:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

postgres-gis: versiontest
	cp `which kubectl` bin/postgres
	cp `which oc` bin/postgres
	docker build -t crunchy-postgres-gis -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres-gis.$(CCP_BASEOS) .
	docker tag crunchy-postgres-gis crunchydata/crunchy-postgres-gis:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

prometheus:	versiontest
	docker build -t crunchy-prometheus -f $(CCP_BASEOS)/Dockerfile.prometheus.$(CCP_BASEOS) .
	docker tag crunchy-prometheus crunchydata/crunchy-prometheus:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

promgateway: versiontest
	docker build -t crunchy-promgateway -f $(CCP_BASEOS)/Dockerfile.promgateway.$(CCP_BASEOS) .
	docker tag crunchy-promgateway crunchydata/crunchy-promgateway:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

upgrade: versiontest
	if [[ '$(CCP_PGVERSION)' != '9.5' ]]; then \
		docker build -t crunchy-upgrade -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.upgrade.$(CCP_BASEOS) . ;\
		docker tag crunchy-upgrade crunchydata/crunchy-upgrade:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION) ;\
	fi

vac: versiontest
	cd vacuum && godep go install vacuum.go
	cp $(GOBIN)/vacuum bin/vacuum
	docker build -t crunchy-vacuum -f $(CCP_BASEOS)/Dockerfile.vacuum.$(CCP_BASEOS) .
	docker tag crunchy-vacuum crunchydata/crunchy-vacuum:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

version:
	docker build -t crunchy-version -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.version.$(CCP_BASEOS) .
	docker tag crunchy-version crunchydata/crunchy-version:$(CCP_BASEOS)-$(CCP_PG_FULLVERSION)-$(CCP_VERSION)

#=================
# Utility targets
#=================
push:
	./bin/push-to-dockerhub.sh
