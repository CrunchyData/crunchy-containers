package tests

import (
	"fmt"
	"os"
	"testing"
)

func TestCustomConfigSSL(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'custom-config-ssl' example...")
	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/custom-config-ssl/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/custom-config-ssl/cleanup.sh", env, t)
	}

	pods := []string{"custom-config-ssl"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Checking SQL...")
	local, remote := randomPort(), 5432
	proxy, err := harness.setupProxy("custom-config-ssl", local, remote)
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()

	certDir := os.ExpandEnv("${CCPROOT}/examples/kube/custom-config-ssl/certs")
	os.Setenv("PGSSLROOTCERT", fmt.Sprintf("%s/%s", certDir, "ca.crt"))
	os.Setenv("PGSSLCERT", fmt.Sprintf("%s/%s", certDir, "client.crt"))
	os.Setenv("PGSSLKEY", fmt.Sprintf("%s/%s", certDir, "client.key"))

	db, err := harness.setupDB("userdb", proxy.Hostname, "testuser", "", "require", local)
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
