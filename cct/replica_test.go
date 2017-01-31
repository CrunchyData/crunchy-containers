package cct

import (
	"database/sql"
	"fmt"
	"testing"
	// "time"
    "github.com/docker/docker/client"

    _ "github.com/lib/pq"
)

func isReplicationStarted(
	docker *client.Client,
	containerId string) (ok bool, err error) {

    conStr, err := buildConnectionString(
	    docker, containerId, "postgres", "postgres")
    if err != nil {
        return
    }

	pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT EXISTS (SELECT 1 from pg_stat_replication
    	WHERE application_name = 'replica' and state = 'streaming');`

    err = pg.QueryRow(query).Scan(&ok)
    if err != nil {
    	return
    }

    return
}

func replSentEqReplay(conStr string) (ok bool, err error) {

	pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT (sent_location = replay_location) from pg_stat_replication 
    	WHERE application_name='replica' and state='streaming';`

    err = pg.QueryRow(query).Scan(&ok)
    if err != nil {
    	return
    }

    return
}

func waitForReplay(
	docker *client.Client, 
	containerId string,
	timeoutSeconds int64) (err error) {

    conStr, err := buildConnectionString(
	    docker, containerId, "postgres", "postgres")
    if err != nil {
        return
    }

    fmt.Printf("Waiting maximum of %d seconds for replay", timeoutSeconds)

    escape := func() (bool, error) {
    	irs, err := isReplicationStarted(docker, containerId)
    	return ! irs, err
    }
    condition1 := func() (bool, error) {
    	return replSentEqReplay(conStr)
    }
    if ok, err := timeoutOrReady(
    	timeoutSeconds,
        escape,
        []func() (bool, error){condition1},
        500); err != nil {
        return err
    } else if ! ok {
        return fmt.Errorf("replication stopped; or timeout expired, and replay has not completed.")
    }

    return
}

func TestDockerReplica(t *testing.T) {

    const exampleName = "master-replica"
    const timeoutSeconds = 60
    const skipCleanup = false

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    fmt.Println("Starting master-replica example, and pausing while example sleeps for 20 seconds")
    cleanup := startDockerExampleForTest(t, buildBase, exampleName)
    defer cleanup(skipCleanup)

    fmt.Printf("\nWaiting maximum of %d seconds for master container", timeoutSeconds)
    masterId, err := waitForPostgresContainer(docker, "master", timeoutSeconds)
    if err != nil {
        t.Fatal("master container did not start")
    }
    t.Log("Started master container: " + masterId)

    fmt.Printf("\nWaiting maximum of %d seconds for replica container", timeoutSeconds)
    replicaId, err := waitForPostgresContainer(docker, "replica", timeoutSeconds)
    if err != nil {
        t.Fatal("master container did not start")
    }
    t.Log("Started replica container: " + replicaId)

    if t.Run("ReplicationStarted", func (t *testing.T) {
    	if ok, err := isReplicationStarted(docker, masterId); err != nil {
    		t.Error(err)
    	} else if ! ok {
    		t.Error("Replication has not started")
    	}
    }); t.Failed() {
    	t.Fatal("Cannot proceed")
    }

    t.Log("Write some data to master")
    facts, err := writeSomeData(docker, masterId)
    if err != nil {
        t.Error(err)
    }
    t.Log(facts)

    t.Log("Waiting for replay")
    if err := waitForReplay(docker, "master", timeoutSeconds); err != nil {
    	t.Fatal(err)
    }

    t.Run("CheckReplica", func (t *testing.T) {
        ok, foundrc, err := assertSomeData(docker, replicaId, facts.rowcount)
        if err != nil {
        	t.Error(err)
        }
        if ! ok {
        	t.Errorf("Expected %d rows; found %d\n", facts.rowcount, foundrc)
        }
    })

    t.Log("All tests complete")
}
