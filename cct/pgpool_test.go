package cct

import (
	"fmt"
	"testing"
	"time"
)

func TestDockerPgPool(t *testing.T) {

    const exampleName = "pgpool"
    const timeoutSeconds = 60
    const skipCleanup = true

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    // masterId, replicaId
    masterId, _, cleanup := startMasterReplica(t, docker, buildBase, timeoutSeconds)
    defer cleanup(skipCleanup)

    if t.Run("ReplicationStarted", func (t *testing.T) {
    	if ok, err := isReplicationStarted(docker, masterId); err != nil {
    		t.Error(err)
    	} else if ! ok {
    		t.Error("Replication has not started")
    	}
    }); t.Failed() {
    	t.Fatal("Cannot proceed")
    }

    fmt.Println("Starting pgpool")
    poolCleanup := startDockerExampleForTest(t, buildBase, "pgpool")
    defer poolCleanup(skipCleanup)

    var containerId string
    if t.Run("StartContainer", func (t *testing.T) {
	    c, err := ContainerFromName(docker, "pgpool")
	    if err != nil {
	    	t.Fatal(err)
	    }
	    containerId = c.ID
	    t.Log("Started pgpool container: " + containerId)
	}); t.Failed() {
    	t.Fatal("Cannot proceed")
	}

    // verify labels match build
    t.Run("Labels", func (t *testing.T) {
        testCCPLabels(docker, containerId, t)
    })

    conStr, err := buildConnectionString(docker, containerId, "testuser", "userdb")
    if err != nil {
    	t.Fatal(err)
    }
    t.Log("pgpool connection string: " + conStr)

    fmt.Println("Sleep 10 to allow pgpool to startup")
    time.Sleep(10 * time.Second)

    if t.Run("TestConnect", func (t *testing.T) {
    	if ok, err := isAcceptingConnectionString(conStr); err != nil {
    		t.Fatal(err)
    	} else if ! ok {
    		t.Fatal("Could not connect to pgpool")
    	}
    }); t.Failed() {
    	t.Fatal("Cannot proceed")
    }

    t.Log("All tests complete.")
}