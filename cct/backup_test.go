/*
 Copyright 2017 Crunchy Data Solutions, Inc.
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

// Crunchy Container Test
package cct

import (
    "fmt"
    "testing"
)

// start basic example, run backup example (pg_basebackup), feed to restore example
func TestDockerBackupRestore(t *testing.T) {
    // const exampleName = "backup"
    const timeoutSeconds = 60
    const skipCleanup = true

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    basicId, basicCleanup := startBasic(t, docker, buildBase, timeoutSeconds)
    defer basicCleanup(skipCleanup)

    t.Log("Write some data to basic container to test backup / restore")
    facts, err := writeSomeData(docker, basicId, userdb)
    if err != nil {
        t.Error(err)
    }

    /////////// basic container is ready, run backup
    cleanup := startDockerExampleForTest(t, buildBase, "backup")
    defer cleanup(skipCleanup)

    // discard basicbackup containerId, we will not need it again
    _ = testContainer(t, "BackupContainer", docker, "basicbackup")
    if t.Failed() {
        t.Fatal("Cannot proceed")
    }

    // wait for backup to finish on basic container
    ok, err := waitForBackup(docker, basicId, timeoutSeconds)
    if err != nil {
        t.Fatal(err)
    } else if ! ok {
        t.Fatalf("Backup did not complete after %n seconds.\n", timeoutSeconds)
    }

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

    fmt.Printf("Waiting for master-restore container to start")
    restoreId, err := waitForPostgresContainer(docker, "master-restore", 60)
    if err != nil {
        t.Error(err)
    }
    defer restoreCleanup(skipCleanup)

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
