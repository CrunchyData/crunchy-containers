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

func TestSync(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'sync' example...")
	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/sync/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/sync/cleanup.sh", env, t)
	}

	pods := []string{"primarysync", "replicaasync", "replicasync"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	host := "primarysync"
	local, remote := randomPort(), 5432
	proxy, err := harness.setupProxy(host, local, remote)
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()

	db, err := harness.setupDB("userdb", proxy.Hostname, "postgres", "password", "disable", local)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	replicas, err := db.Replication()
	if err != nil {
		t.Fatal(err)
	}

	if len(replicas) < 1 {
		t.Fatalf("Replica count should be greater than 0: actual %d", len(replicas))
	}

	var sync bool
	for _, v := range replicas {
		if v.SyncState == "sync" {
			sync = true
		}
	}

	if !sync {
		t.Fatalf("No sync replica detected, there should be.")
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
