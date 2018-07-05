package data

import (
	"testing"
)

func TestPostgreSQL_Replication(t *testing.T) {
	cleanup := preparePostgresTestContainer(t, primaryOptions, primaryConn)
	defer cleanup()

	primaryDB, err := primaryConn.NewDB()
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}

	replicaCleanup := preparePostgresTestContainer(t, replicaOptions, replicaConn)
	defer replicaCleanup()

	_, err = replicaConn.NewDB()
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}

	replicas, err := primaryDB.Replication()
	if len(replicas) < 1 {
		t.Fatalf("No replicas found (there should be): %d", len(replicas))
	}
}
