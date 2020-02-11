package data

/*
Copyright 2018 - 2020 Crunchy Data Solutions, Inc.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

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
