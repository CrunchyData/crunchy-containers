package data

import (
	"testing"
)

func TestPostgreSQL_CRUD(t *testing.T) {
	cleanup := preparePostgresTestContainer(t, primaryOptions, primaryConn)
	defer cleanup()

	db, err := primaryConn.NewDB()
	if err != nil {
		t.Fatalf("Could not create database connection: %s", err)
	}

	err = db.InitDDL()
	if err != nil {
		t.Fatalf("Error initializing DDL: %s", err)
	}

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

	coffee, err := db.GetCoffee("Ethiopian Yirgacheffe")
	if err != nil {
		t.Fatalf("Error retrieving data from table: %s", err)
	}

	if coffee.Name == "" {
		t.Fatal("Returned data from table is null, shouldn't be")
	}

	err = db.CoffeeDeleteAll()
	if err != nil {
		t.Fatalf("Error deleting table data: %s", err)
	}
}
