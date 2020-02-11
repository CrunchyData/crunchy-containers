package tests

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

func TestSecret(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'secret' example...")
	harness := setup(t, timeout, true)

	env := []string{}
	_, err := harness.runExample("examples/kube/secret/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/secret/cleanup.sh", env, t)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, []string{"secret"}); err != nil {
		t.Fatal(err)
	}

	local, remote := randomPort(), 5432
	proxy, err := harness.setupProxy("secret", local, remote)
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()

	db, err := harness.setupDB("userdb", proxy.Hostname, "postgres", "password", "disable", local)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	extensions, err := db.AllExtensions()
	if err != nil {
		t.Fatal(err)
	}

	if len(extensions) < 1 {
		t.Fatalf("extensions less then 1, it shouldn't be: %d", len(extensions))
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
