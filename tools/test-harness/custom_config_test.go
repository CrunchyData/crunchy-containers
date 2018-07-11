package tests

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
	nsswrapper := []string{"env", "LD_PRELOAD=/usr/lib64/libnss_wrapper.so", "NSS_WRAPPER_PASSWD=/tmp/passwd", "NSS_WRAPPER_GROUP=/tmp/group"}
	fullBackup := []string{"/usr/bin/pgbackrest", "--stanza=db", "backup", "--type=full"}
	cmd := append(nsswrapper, fullBackup...)
	_, stderr, err := harness.Client.Exec(harness.Namespace, "custom-config", "postgres", cmd)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Log("Checking PGWAL...")
	cmd = []string{"test", "-d", "/pgwal/custom-config-wal"}
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

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
