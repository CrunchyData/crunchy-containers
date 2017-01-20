package cct

import (
	"database/sql"
	"fmt"
	"os"
	"os/exec"
	"path"
	"testing"
	"time"

	"github.com/docker/docker/client"
	// "github.com/docker/docker/api/types/container"

	_ "github.com/lib/pq"
)

// all example user passwords are the same
const pgpassword string = "password"

// return a simple connection string to docker host with password in plaintext
func buildConnectionString(
	docker *client.Client,
	containerId string, 
	database string, 
	user string) (conStr string, err error) {

	host, port, err := pgHostFromContainer(docker, containerId)
	if err != nil {
		return
	}

	if host == "" {
		dockerHost := os.Getenv("DOCKER_HOST")
		if dockerHost == "" {
			host = "localhost"
		} else {
			host = dockerHost
		}
	}
	conStr = fmt.Sprintf("host=%s port=%s database=%s user=%s password=%s sslmode=disable",
		host, port, database, user, pgpassword)
	return
}

// does role exist on specified host?
func roleExists(conStr *string, roleName string) (ok bool, err error) {
    pg, err := sql.Open("postgres", *conStr)
    if err != nil {
    	return
    }
    defer pg.Close()

	err = pg.QueryRow("SELECT EXISTS (SELECT 1 from pg_roles WHERE rolname = $1);", 
		roleName).Scan(&ok)
	if err != nil {
		return
	}

	return
}

// does database exist on specified host?
func dbExists(conStr *string, dbName string) (ok bool, err error) {
    pg, err := sql.Open("postgres", *conStr)
    if err != nil {
    	return
    }
    defer pg.Close()

	err = pg.QueryRow("SELECT EXISTS (SELECT 1 from pg_database WHERE datname = $1);", 
		dbName).Scan(&ok)
	if err != nil {
		return
	}
	return
}

// docker basic example expects one container named basic running 
// crunchy-postgres (latest should equal $CCP_IMAGE_TAG)
func TestDockerBasic(t *testing.T) {
    const testName = "basic"
    const testInitTimeoutSeconds = 20

    buildBase := os.Getenv("BUILDBASE")
    if buildBase == "" {
    	t.Fatal("Please set BUILDBASE environment variable to run tests.")
    }

    pathToTest := path.Join(
    	buildBase, "examples", "docker", testName, "run.sh")
    pathToCleanup := path.Join(
    	buildBase, "examples", "docker", testName, "cleanup.sh")

    t.Log("Initializing docker client")
    docker, err := client.NewEnvClient()
    if err != nil {
        t.Fatal(err)
    }

    defer docker.Close()

    /////////// docker is available, run the example
    t.Log("Starting Example: docker/" + testName)
    cmdout, err := exec.Command(pathToTest).CombinedOutput()
    t.Logf("%s\n", cmdout)
    if err != nil {
    	t.Fatal(err)
    }

    c, err := ContainerFromName(docker, "basic")
    if err != nil {
    	t.Fatal(err)
    }

    fmt.Printf("Waiting for %d seconds.\n", testInitTimeoutSeconds)

    /////////// allow container to start and db to initialize
    t.Logf("Waiting %d seconds for container and postgres startup\n", testInitTimeoutSeconds)
    // timer := time.NewTimer(time.Second * testInitTimeoutSeconds)
    // ticker := time.NewTicker(time.Millisecond * 500)

    time.Sleep(time.Second * testInitTimeoutSeconds)

    if isrunning, err := isContainerRunning(docker, c.ID); err != nil {
    	t.Fatal(err)
    } else if ! isrunning {
    	t.Fatal("Container is not running, cannot continue")
    }   

    if isready, err := isPostgresReady(docker, c.ID); err != nil {
    	t.Fatal(err)
    } else if ! isready {
    	t.Fatalf("Postgres failed to start after %d seconds\n", testInitTimeoutSeconds)
    }
    

    /////////// begin database tests
    var userName string = "testuser"
    var dbName string = "userdb"

    pgUserConStr, err := buildConnectionString(docker, c.ID, "postgres", "postgres")
    if err != nil {
    	t.Fatal(err)
    }
    t.Log("Connection String: " + pgUserConStr)

    t.Run("Connect", func (t *testing.T) {
	    pg, err := sql.Open("postgres", pgUserConStr)
	    if err != nil {
	    	t.Fatal(err)
	    }
	    _, err = pg.Query("SELECT 1;")
	    if err != nil {
	    	t.Fatal(err)
	    }
	    pg.Close()
	})
    t.Run("RoleExists", func (t *testing.T) {
    	if ok, err := roleExists(&pgUserConStr, userName); err != nil {
    		t.Error(err)
    	} else if ! ok {
    		t.Errorf("The %s ROLE was not created.\n", userName)
    	}
    })
    t.Run("DatabaseExists", func (t *testing.T) {
    	if ok, err := dbExists(&pgUserConStr, dbName); err != nil {
    		t.Error(err)
    	} else if ! ok {
    		t.Error("The %s DATABASE was not created.\n", dbName)
    	}
    })

	// TestObjectCreate

	// TestRoleCreate

	// TestGrantObjectOwnerToRole

	// TestExtensionExists
	// 	pg_stat_statements
	//	pgaudit

	// TestLocale en_US.utf-8

    /////////// test user
    // userConStr := buildConnectionString(docker, c.ID, dbName, userName)

    // pg, err = sql.Open("postgres", userConStr)
    // if err != nil {
    // 	t.Error(err)
    // }
    // defer pg.Close()

	// TestTempTable

	// TestObjectCreate

	// TestInsert

    /////////// completed tests, cleanup
    t.Log("Calling cleanup" + pathToCleanup)
    // cmdout, err = exec.Command(pathToCleanup).CombinedOutput()
    // t.Logf("%s", cmdout)
    // if err != nil {
    // 	t.Fatal(err)
    // }

    // test container is destroyed
    // test volume is destroyed
}


// Benchmark pgbench
