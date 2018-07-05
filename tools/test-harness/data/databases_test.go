package data

import (
	"testing"
)

func TestPostgreSQL_Databases(t *testing.T) {
	cleanup := preparePostgresTestContainer(t, primaryOptions, primaryConn)
	defer cleanup()

	db, err := primaryConn.NewDB()
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}

	roles, err := db.Databases()
	if err != nil {
		t.Fatalf("Error retrieving databases: %s", err)
	}

	if len(roles) == 0 {
		t.Fatalf("Databases slice is empty, it shouldn't be.")
	}
}
