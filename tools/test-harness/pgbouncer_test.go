package tests

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

func TestPGBouncer(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'pgbouncer' example...")
	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/pgbouncer/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/pgbouncer/cleanup.sh", env, t)
	}

	pods := []string{"pg-primary", "pg-replica", "pgbouncer-primary", "pgbouncer-replica"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	primaryHost := "pgbouncer-primary"
	primaryLocalPort, primaryRemotePort := randomPort(), 6432
	primaryProx, err := harness.setupProxy(primaryHost, primaryLocalPort, primaryRemotePort)
	if err != nil {
		t.Fatal(err)
	}
	defer primaryProx.Close()

	replicaHost := "pgbouncer-replica"
	replicaLocalPort, replicaRemotePort := randomPort(), 6432
	replicaProx, err := harness.setupProxy(replicaHost, replicaLocalPort, replicaRemotePort)
	if err != nil {
		t.Fatal(err)
	}
	defer replicaProx.Close()

	db, err := harness.setupDB("userdb", primaryProx.Hostname, "testuser", "password", "disable", primaryLocalPort)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	_ = db.RunCRUD()

	replicas, err := db.Replication()
	if err != nil {
		t.Fatal(err)
	}

	if len(replicas) < 1 {
		t.Fatalf("Replica count should be greater than 0: actual %d", len(replicas))
	}
	db.Close()

	db, err = harness.setupDB("userdb", replicaProx.Hostname, "testuser", "password", "disable", replicaLocalPort)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	coffee, err := db.AllCoffee()
	if err != nil {
		t.Fatal(err)
	}

	if len(coffee) < 1 {
		t.Fatal("Data read from replica shouldn't be empty (it is)")
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
