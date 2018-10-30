package tests

import (
    "time"
	"testing"
)

func TestBackrestAsyncArchiveGIS(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backrest/async-archiving' example...")

    // Extra time because GIS causes backup to take longer.
    gisTimeout := time.Second * 240
    harness := setup(t, gisTimeout, true)

	env := []string{"CCP_PG_IMAGE=-gis"}
	_, err := harness.runExample("examples/kube/backrest/async-archiving/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/backrest/async-archiving/cleanup.sh", env, t)
	}

	pods := []string{"backrest-async-archive"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/usr/bin/pgbackrest", "--stanza=db", "backup", "--type=full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, "backrest-async-archive", "backrest", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Log("Running diff backup...")
	diffBackup := []string{"/usr/bin/pgbackrest", "--stanza=db", "backup", "--type=full"}
	_, stderr, err = harness.Client.Exec(harness.Namespace, "backrest-async-archive", "backrest", diffBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}

func TestBackrestDeltaRestoreGIS(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backrest/delta' example...")

    // Extra time because GIS causes backup to take longer.
    gisTimeout := time.Second * 240
    harness := setup(t, gisTimeout, true)

	env := []string{"CCP_PG_IMAGE=-gis"}
	_, err := harness.runExample("examples/kube/backrest/backup/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/backrest/backup/cleanup.sh", env, t)
	}

	t.Log("Checking if pods are ready to use...")
	pods := []string{"backrest"}
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/usr/bin/pgbackrest", "--stanza=db", "backup", "--type=full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, "backrest", "backrest", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	// Delta Restore
	_, err = harness.runExample("examples/kube/backrest/delta/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.runExample("examples/kube/backrest/delta/cleanup.sh", env, t)
	}

	t.Log("Checking if job has completed...")
	job, err := harness.Client.GetJob(harness.Namespace, "backrest-delta-restore-job")
	if err != nil {
		t.Fatal(err)
	}

	if err := harness.Client.IsJobComplete(harness.Namespace, job); err != nil {
		t.Fatal(err)
	}

	_, err = harness.runExample("examples/kube/backrest/delta/post-restore.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run 'post-restore.sh': %s", err)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}

func TestBackrestFullRestoreGIS(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backrest/full' example...")

    // Extra time because GIS causes backup to take longer.
    gisTimeout := time.Second * 240
    harness := setup(t, gisTimeout, true)

	env := []string{"CCP_PG_IMAGE=-gis"}
	_, err := harness.runExample("examples/kube/backrest/backup/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/backrest/backup/cleanup.sh", env, t)
	}

	t.Log("Checking if pods are ready to use...")
	pods := []string{"backrest"}
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/usr/bin/pgbackrest", "--stanza=db", "backup", "--type=full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, "backrest", "backrest", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	// Full Restore
	_, err = harness.runExample("examples/kube/backrest/full/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.runExample("examples/kube/backrest/full/cleanup.sh", env, t)
	}

	t.Log("Checking if job has completed...")
	job, err := harness.Client.GetJob(harness.Namespace, "backrest-full-restore-job")
	if err != nil {
		t.Fatal(err)
	}

	if err := harness.Client.IsJobComplete(harness.Namespace, job); err != nil {
		t.Fatal(err)
	}

	_, err = harness.runExample("examples/kube/backrest/full/post-restore.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run 'post-restore.sh': %s", err)
	}

	t.Log("Checking if pods are ready to use...")
	restoredPod := []string{"backrest-full-restored"}
	if err := harness.Client.CheckPods(harness.Namespace, restoredPod); err != nil {
		t.Fatal(err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}

func TestBackrestPITRRestoreGIS(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backrest/pitr' example...")

    // Extra time because GIS causes backup to take longer.
    gisTimeout := time.Second * 240
    harness := setup(t, gisTimeout, true)

	env := []string{"CCP_PG_IMAGE=-gis"}
	_, err := harness.runExample("examples/kube/backrest/backup/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/backrest/backup/cleanup.sh", env, t)
	}

	t.Log("Checking if pods are ready to use...")
	pods := []string{"backrest"}
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/usr/bin/pgbackrest", "--stanza=db", "backup", "--type=full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, "backrest", "backrest", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	// PITR Restore
	out, err := harness.runExample("examples/kube/backrest/pitr/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s %s", out, err)
	}
	if harness.Cleanup {
		defer harness.runExample("examples/kube/backrest/pitr/cleanup.sh", env, t)
	}

	t.Log("Checking if job has completed...")
	job, err := harness.Client.GetJob(harness.Namespace, "backrest-pitr-restore-job")
	if err != nil {
		t.Fatal(err)
	}

	if err := harness.Client.IsJobComplete(harness.Namespace, job); err != nil {
		t.Fatal(err)
	}

	_, err = harness.runExample("examples/kube/backrest/pitr/post-restore.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run 'post-restore.sh': %s", err)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
