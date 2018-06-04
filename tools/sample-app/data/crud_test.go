package data

import (
	"testing"
)

func testInit(t *testing.T) {
	db, err := NewDB(connURL.URL())
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}

	err = db.InitDDL()
	if err != nil {
		t.Fatalf("Error initializing DDL: %s", err)
	}
}

func TestPostgreSQL_CRUD(t *testing.T) {
	cleanup := preparePostgresTestContainer(t)
	defer cleanup()

	db, err := NewDB(connURL.URL())
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}
	testInit(t)

	for _, coffee := range coffees {
		err = db.AddCoffee(coffee)
		if err != nil {
			t.Fatalf("Error inserting data: %s", err)
		}
	}

	result, err := db.AllCoffee()
	if len(result) <= 0 {
		t.Fatalf("Result slice is empty, it shouldn't be.")
	}

	c, err := db.Coffee("Ethiopian Yirgacheffe")
	if err != nil {
		t.Fatalf("Error retrieving data from table: %s", err)
	}

	if c.Name == "" {
		t.Fatal("Returned data from table is null, shouldn't be")
	}

	err = db.CoffeeDeleteAll()
	if err != nil {
		t.Fatalf("Error deleting table data: %s", err)
	}
}
