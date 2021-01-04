package data

/*
Copyright 2018 - 2021 Crunchy Data Solutions, Inc.
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
