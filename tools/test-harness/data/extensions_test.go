package data

import (
	"testing"
)

func TestPostgreSQL_Extensions(t *testing.T) {

	cleanup := preparePostgresTestContainer(t, primaryOptions, primaryConn)
	defer cleanup()

	db, err := primaryConn.NewDB()
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}

	extensions, err := db.AllExtensions()
	if err != nil {
		t.Fatalf("Error retrieving all extensions: %s", err)
	}

	if len(extensions) == 0 {
		t.Fatalf("Extensions slice is empty, it shouldn't be.")
	}

	extensions, err = db.InstalledExtensions()
	if err != nil {
		t.Fatalf("Error retrieving installed extensions: %s", err)
	}

	if len(extensions) == 0 {
		t.Fatalf("Extensions slice is empty, it shouldn't be.")
	}
}
