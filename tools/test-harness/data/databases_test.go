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
