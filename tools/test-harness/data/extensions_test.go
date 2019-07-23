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

func TestPostgreSQL_ExtensionsExpected(t *testing.T) {

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

	expectedExt := map[string]bool {
		"plpythonu": false,
	}

	for _, ext := range extensions {
		if _, ok := expectedExt[ext.Name]; ok {
			expectedExt[ext.Name] = true
		}
	}

	for name, ext := range expectedExt {
		if !ext {
			t.Errorf("Extension %s was not found.", name)
		}
	}
}
