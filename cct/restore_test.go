package cct

import (
	"fmt"
    "path"
	"testing"
)

func TestDockerRestore(t *testing.T) {

    const timeoutSeconds = 60
    const skipCleanup = true

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    // cleanup basic & backup examples from TestDockerBackup
    clnPath := func (basePath, name string) string {
        return path.Join(basePath, "examples", "docker", name, "cleanup.sh")
    }

    defer cleanupTest(t, skipCleanup, "basic", clnPath(buildBase, "basic"))
    defer cleanupTest(t, skipCleanup, "backup", clnPath(buildBase, "backup"))

	var backupName string
    if t.Run("CheckBackup", func (t *testing.T) {

        if ok, name, err := getBackupName(
            docker, "basicbackup", "/pgdata/basic-backups");
        name == "" {
            t.Error("No backup found in basicbackup container.")
        } else if err != nil {
            t.Log("Got backup name: " + name)
            t.Error(err)
        } else if ! ok {
            t.Log("Got backup name: " + name)
            t.Error("File not found in backup path.")
        } else {
            backupName = name
        }

        t.Log("Created backup: " + backupName)

    }); t.Failed() {
        t.Fatal("Cannot proceed")
    }

    t.Log("Starting restore")
    restoreCleanup := startDockerExampleForTest(t, buildBase, "restore", backupName)
    defer restoreCleanup(skipCleanup)

    fmt.Printf("Waiting maximum %d seconds for primary-restore container to start", timeoutSeconds)
    restoreId, err := waitForPostgresContainer(docker, "primary-restore", timeoutSeconds)
    if err != nil {
        t.Error(err)
    }

    facts, err := getFacts(docker, restoreId, userdb, "some_table")
    if err != nil {
    	t.Fatal(err)
    }

    t.Run("CheckRestoreData", func(t *testing.T) {
        if ok, found, err := assertSomeData(
            docker, restoreId, userdb, facts); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("Restore failed. Expected %n rows, %n bytes\nfound %n rows, %n bytes\n",
                facts.rowcount, facts.relsize, found.rowcount, found.relsize)
        }
    })

    t.Log("All tests complete")
}