package tests

import (
	"fmt"
	"strings"
	"testing"
)

const testTableName = "backrestTestTable"

func TestBackrestAsyncArchive(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backrest/async-archiving' example...")
	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/backrest/async-archiving/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/backrest/async-archiving/cleanup.sh", env, t)
	}

	t.Log("Checking if backrest deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "backrest-async-archive"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "backrest-async-archive")
	if err != nil {
		t.Fatal(err)
	}

	if len(primary) == 0 {
		t.Fatal("Backrest deployment ready but no pods found")
	}

	var pods []string
	for _, pod := range primary {
		pods = append(pods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/opt/cpm/bin/pgbackrest_backup.sh", "full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "backrest", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Log("Running diff backup...")
	diffBackup := []string{"/opt/cpm/bin/pgbackrest_backup.sh", "diff"}
	_, stderr, err = harness.Client.Exec(harness.Namespace, pods[0], "backrest", diffBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Logf("Verifying that backups have been created successfully...")
	// Verify that backups have been created successfully
	backupsExists := []string{"/usr/bin/pgbackrest", "info", "--stanza=db",
		"--repo1-path=/backrestrepo/backrest-async-archive-backups"}
	stdout, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "backrest", backupsExists)
	if strings.Contains(stdout, "full backup") {
		t.Log("Full backup created successfully")
	} else {
		t.Fatal("Full backup was unsuccessful")
	}
	if strings.Contains(stdout, "diff backup") {
		t.Log("Diff backup created successfully")
	} else {
		t.Fatal("Diff backup was unsuccessful")
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}

func TestBackrestDeltaRestore(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backrest/delta' example...")

	harness := setup(t, timeout, true)
	backupEnv := []string{}
	_, err := harness.runExample("examples/kube/backrest/backup/run.sh", backupEnv, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/backrest/backup/cleanup.sh", backupEnv, t)
	}

	t.Log("Checking if backrest deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "backrest"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "backrest")
	if err != nil {
		t.Fatal(err)
	}

	if len(primary) == 0 {
		t.Fatal("Backrest deployment ready but no pods found")
	}

	var pods []string
	for _, pod := range primary {
		pods = append(pods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/opt/cpm/bin/pgbackrest_backup.sh", "full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "backrest", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Logf("Verifying that test table %s does not yet exist...", testTableName)
	// Verify that test table does not yet exist
	tableExists := []string{"/usr/bin/psql", "-c", fmt.Sprintf("table \"%s\"", testTableName)}
	_, stderr, err = harness.Client.Exec(harness.Namespace, pods[0], "backrest", tableExists)
	if strings.Contains(stderr, fmt.Sprintf("ERROR:  relation \"%s\" does not exist", testTableName)) {
		t.Logf("Verified that table %s does not exist", testTableName)
	} else if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Log("Capturing current timestamp before table creation...")
	// Capture current timestamp
	currentTimestamp := []string{"/usr/bin/psql", "-c", "select current_timestamp"}
	stdout, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "backrest", currentTimestamp)
	timestamp := strings.TrimSpace(strings.Split(stdout, "\n")[2])
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	} else {
		t.Logf("Captured the current timestamp: %s", timestamp)
	}

	t.Logf("Creating test table %s...", testTableName)
	// Create test table
	createTable := []string{"/usr/bin/psql", "-c", fmt.Sprintf("create table \"%s\" (id int)", testTableName)}
	_, stderr, err = harness.Client.Exec(harness.Namespace, pods[0], "backrest", createTable)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	} else {
		t.Logf("Created table %s", testTableName)
	}

	t.Logf("Verifying that test table %s now exists...", testTableName)
	// Verify that test table does not yet exist
	tableExists = []string{"/usr/bin/psql", "-c", fmt.Sprintf("table \"%s\"", testTableName)}
	stdout, stderr, err = harness.Client.Exec(harness.Namespace, pods[0], "backrest", tableExists)
	if err == nil {
		t.Logf("Verified that table %s exists", testTableName)
	} else {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	deltaEnv := []string{fmt.Sprintf("CCP_BACKREST_TIMESTAMP=%s", timestamp)}
	// Delta Restore
	_, err = harness.runExample("examples/kube/backrest/delta/run.sh", deltaEnv, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.runExample("examples/kube/backrest/delta/cleanup.sh", deltaEnv, t)
	}

	t.Log("Checking if job has completed...")
	job, err := harness.Client.GetJob(harness.Namespace, "backrest-delta-restore-job")
	if err != nil {
		t.Fatal(err)
	}

	if err := harness.Client.IsJobComplete(harness.Namespace, job); err != nil {
		t.Fatal(err)
	}

	postEnv := []string{}
	// Run post-restore script
	_, err = harness.runExample("examples/kube/backrest/delta/post-restore.sh", postEnv, t)
	if err != nil {
		t.Fatalf("Could not run 'post-restore.sh': %s", err)
	}

	t.Log("Checking if backrest deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "backrest-delta-restored"); !ok {
		t.Fatal(err)
	}

	restored, err := harness.Client.GetDeploymentPods(harness.Namespace, "backrest-delta-restored")
	if err != nil {
		t.Fatal(err)
	}

	if len(restored) == 0 {
		t.Fatal("Backrest Restored deployment ready but no pods found")
	}

	var restoredPods []string
	for _, pod := range restored {
		restoredPods = append(restoredPods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, restoredPods); err != nil {
		t.Fatal(err)
	}

	t.Logf("Verifying that test table %s no longer exists due to the restore...", testTableName)
	// Verify that test table does not yet exist
	tableExists = []string{"/usr/bin/psql", "-c", fmt.Sprintf("table \"%s\"", testTableName)}
	_, stderr, err = harness.Client.Exec(harness.Namespace, restoredPods[0], "backrest", tableExists)
	if strings.Contains(stderr, fmt.Sprintf("ERROR:  relation \"%s\" does not exist", testTableName)) {
		t.Logf("Verified that table %s no longer exists", testTableName)
	} else if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}

func TestBackrestFullRestore(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backrest/full' example...")

	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/backrest/backup/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/backrest/backup/cleanup.sh", env, t)
	}

	t.Log("Checking if backrest deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "backrest"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "backrest")
	if err != nil {
		t.Fatal(err)
	}

	if len(primary) == 0 {
		t.Fatal("Backrest deployment ready but no pods found")
	}

	var pods []string
	for _, pod := range primary {
		pods = append(pods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/opt/cpm/bin/pgbackrest_backup.sh", "full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "backrest", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Logf("Creating test table %s...", testTableName)
	// Create test table
	createTable := []string{"/usr/bin/psql", "-c", fmt.Sprintf("create table \"%s\" (id int)", testTableName)}
	_, stderr, err = harness.Client.Exec(harness.Namespace, pods[0], "backrest", createTable)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	} else {
		t.Logf("Created table %s", testTableName)
	}

	t.Logf("Verifying that test table %s now exists...", testTableName)
	// Verify that test table does not yet exist
	tableExists := []string{"/usr/bin/psql", "-c", fmt.Sprintf("table \"%s\"", testTableName)}
	stdout, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "backrest", tableExists)
	if err == nil {
		t.Logf("Verified that table %s exists", testTableName)
	} else {
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

	t.Log("Checking if backrest deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "backrest-full-restored"); !ok {
		t.Fatal(err)
	}

	restored, err := harness.Client.GetDeploymentPods(harness.Namespace, "backrest-full-restored")
	if err != nil {
		t.Fatal(err)
	}

	if len(restored) == 0 {
		t.Fatal("Backrest Restored deployment ready but no pods found")
	}

	var restoredPods []string
	for _, pod := range restored {
		restoredPods = append(restoredPods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, restoredPods); err != nil {
		t.Fatal(err)
	}

	t.Logf("Verifying that table %s still exists...", testTableName)
	// Verify that test table does not yet exist
	tableExists = []string{"/usr/bin/psql", "-c", fmt.Sprintf("table \"%s\"", testTableName)}
	stdout, stderr, err = harness.Client.Exec(harness.Namespace, restoredPods[0], "backrest", tableExists)
	if strings.Contains(stdout, "(0 rows)") {
		t.Logf("Verified that table %s exists", testTableName)
	} else if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}

func TestBackrestPITRRestore(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backrest/pitr' example...")

	harness := setup(t, timeout, true)
	backupEnv := []string{}
	_, err := harness.runExample("examples/kube/backrest/backup/run.sh", backupEnv, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/backrest/backup/cleanup.sh", backupEnv, t)
	}

	t.Log("Checking if backrest deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "backrest"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "backrest")
	if err != nil {
		t.Fatal(err)
	}

	if len(primary) == 0 {
		t.Fatal("Backrest deployment ready but no pods found")
	}

	var pods []string
	for _, pod := range primary {
		pods = append(pods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Running full backup...")
	// Required for OCP - backrest gets confused when random UIDs aren't found in PAM.
	// Exec doesn't load bashrc or bash_profile, so we need to set this explicitly.
	fullBackup := []string{"/opt/cpm/bin/pgbackrest_backup.sh", "full"}
	_, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "backrest", fullBackup)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Logf("Verifying that test table %s does not yet exist...", testTableName)
	// Verify that test table does not yet exist
	tableExists := []string{"/usr/bin/psql", "-c", fmt.Sprintf("table \"%s\"", testTableName)}
	_, stderr, err = harness.Client.Exec(harness.Namespace, pods[0], "backrest", tableExists)
	if strings.Contains(stderr, fmt.Sprintf("ERROR:  relation \"%s\" does not exist", testTableName)) {
		t.Logf("Verified that table %s does not exist", testTableName)
	} else if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	t.Log("Capturing current timestamp before table creation...")
	// Capture current timestamp
	currentTimestamp := []string{"/usr/bin/psql", "-c", "select current_timestamp"}
	stdout, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "backrest", currentTimestamp)
	timestamp := strings.TrimSpace(strings.Split(stdout, "\n")[2])
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	} else {
		t.Logf("Captured the current timestamp: %s", timestamp)
	}

	t.Logf("Creating test table %s...", testTableName)
	// Create test table
	createTable := []string{"/usr/bin/psql", "-c", fmt.Sprintf("create table \"%s\" (id int)", testTableName)}
	_, stderr, err = harness.Client.Exec(harness.Namespace, pods[0], "backrest", createTable)
	if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	} else {
		t.Logf("Created table %s", testTableName)
	}

	t.Logf("Verifying that test table %s now exists...", testTableName)
	// Verify that test table does not yet exist
	tableExists = []string{"/usr/bin/psql", "-c", fmt.Sprintf("table \"%s\"", testTableName)}
	stdout, stderr, err = harness.Client.Exec(harness.Namespace, pods[0], "backrest", tableExists)
	if err == nil {
		t.Logf("Verified that table %s exists", testTableName)
	} else {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	pitrEnv := []string{fmt.Sprintf("CCP_BACKREST_TIMESTAMP=%s", timestamp)}
	// PITR Restore
	out, err := harness.runExample("examples/kube/backrest/pitr/run.sh", pitrEnv, t)
	if err != nil {
		t.Fatalf("Could not run example: %s %s", out, err)
	}
	if harness.Cleanup {
		defer harness.runExample("examples/kube/backrest/pitr/cleanup.sh", pitrEnv, t)
	}

	t.Log("Checking if job has completed...")
	job, err := harness.Client.GetJob(harness.Namespace, "backrest-pitr-restore-job")
	if err != nil {
		t.Fatal(err)
	}

	if err := harness.Client.IsJobComplete(harness.Namespace, job); err != nil {
		t.Fatal(err)
	}

	postEnv := []string{}
	_, err = harness.runExample("examples/kube/backrest/pitr/post-restore.sh", postEnv, t)
	if err != nil {
		t.Fatalf("Could not run 'post-restore.sh': %s", err)
	}

	t.Log("Checking if backrest deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "backrest-pitr-restored"); !ok {
		t.Fatal(err)
	}

	restored, err := harness.Client.GetDeploymentPods(harness.Namespace, "backrest-pitr-restored")
	if err != nil {
		t.Fatal(err)
	}

	if len(restored) == 0 {
		t.Fatal("Backrest Restored deployment ready but no pods found")
	}

	var restoredPods []string
	for _, pod := range restored {
		restoredPods = append(restoredPods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, restoredPods); err != nil {
		t.Fatal(err)
	}

	t.Logf("Verifying that test table %s no longer exists due to the restore...", testTableName)
	// Verify that test table does not yet exist
	tableExists = []string{"/usr/bin/psql", "-c", fmt.Sprintf("table \"%s\"", testTableName)}
	_, stderr, err = harness.Client.Exec(harness.Namespace, restoredPods[0], "backrest", tableExists)
	if strings.Contains(stderr, fmt.Sprintf("ERROR:  relation \"%s\" does not exist", testTableName)) {
		t.Logf("Verified that table %s no longer exists", testTableName)
	} else if err != nil {
		t.Logf("\n%s", stderr)
		t.Fatalf("Error execing into container: %s", err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
