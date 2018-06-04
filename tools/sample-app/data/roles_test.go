package data

import (
	"testing"
)

func TestPostgreSQL_Roles(t *testing.T) {
	cleanup := preparePostgresTestContainer(t)
	defer cleanup()

	db, err := NewDB(connURL.URL())
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}

	roles, err := db.Roles()
	if err != nil {
		t.Fatalf("Error retrieving roles: %s", err)
	}

	if len(roles) == 0 {
		t.Fatalf("Roles slice is empty, it shouldn't be.")
	}
}
