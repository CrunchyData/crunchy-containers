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

func TestCustomConfig(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'custom-config' example...")
	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/custom-config/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/custom-config/cleanup.sh", env, t)
	}

	pods := []string{"custom-config"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/usr/bin/pgbackrest", "backup", "--stanza=db", "--pg1-path=/pgdata/custom-config",
		"--repo1-path=/backrestrepo/custom-config-backups", "--log-path=/tmp", "--type=full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, "custom-config", "postgres", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Log("Checking PGWAL...")
	cmd := []string{"test", "-d", "/pgwal/custom-config-wal"}
	_, stderr, err = harness.Client.Exec(harness.Namespace, "custom-config", "postgres", cmd)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Log("Checking SQL...")
	local, remote := randomPort(), 5432
	proxy, err := harness.setupProxy("custom-config", local, remote)
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

	settings, err := db.Settings()
	if err != nil {
		t.Fatal(err)
	}

	for _, setting := range settings {
		if setting.Name == "log_timezone" && setting.Value != "UTC" {
			t.Fatalf("log_timezone isn't UTC, it should be: %s = %s", setting.Name, setting.Value)
		}
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
