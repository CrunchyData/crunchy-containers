package data

import (
	"testing"
)

func TestPostgreSQL_Settings(t *testing.T) {
	cleanup := preparePostgresTestContainer(t, primaryOptions, primaryConn)
	defer cleanup()

	db, err := primaryConn.NewDB()
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}

	settings, err := db.Settings()
	if err != nil {
		t.Fatalf("Error retrieving settings: %s", err)
	}

	if len(settings) == 0 {
		t.Fatalf("Settings slice is empty, it shouldn't be.")
	}
}
