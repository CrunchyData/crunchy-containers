package cct

import (
    "database/sql"
    "fmt"
    "os"
    "os/exec"
    "path"
    // "sync"
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

// assert a configurable parameter is set to value 
func assertPostgresConf(
    conStr string, 
    setting string, 
    value string) (ok bool, foundval string, err error) {

    pg, err := sql.Open("postgres", conStr)
    if err != nil {
        return
    }
    defer pg.Close()

    // show command does not support $1 style variable replacement
    show := fmt.Sprintf("SHOW %s;", setting)

    err = pg.QueryRow(show).Scan(&foundval)
    if err != nil {
        return
    }

    ok = (foundval == value)
    return
}

func testLabelMatchesEnv(
    testName string,
    labels map[string]string,
    label string,
    env string,
    t *testing.T) {

    envVal := os.Getenv(env)
    if envVal == "" {
        t.Errorf("The %s environment variable is not set.\n", env)
    }
    t.Run(testName, func (t *testing.T) {
        if ok, found, err := assertLabelFromLabels(
            labels, label, envVal); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("The %s label is set to the value: %s\nExpected: %s\n",
                label, found, envVal)
        }
    })
}

func testCCPLabels(
    docker *client.Client, 
    containerId string,
    t *testing.T) {

    labels, err := getLabels(docker, containerId)
    if err != nil {
        t.Error(err)
    }

    testLabelMatchesEnv(
        "CheckPostgresVersionLabel",
        labels,
        "PostgresVersion",
        "CCP_PGVERSION",
        t)

    testLabelMatchesEnv(
        "CheckReleaseLabel",
        labels,
        "Release",
        "CCP_VERSION",
        t)
}

// Waits maximum of timeout seconds to see if all conditions are true.
// Will escape if escape is true. Returns false if timeout expired without meeting conditions
func timeoutOrReady(
    timeoutSeconds int64,
    escape func() (bool, error),
    conditions []func() (bool, error),
    conditionCheckMilliseconds int64) (ready bool, err error) {

    ready = false

    doneC := make(chan bool)

    timer := time.AfterFunc(time.Second * time.Duration(timeoutSeconds), func() {
        close(doneC)
    })

    ticker := time.NewTicker(time.Millisecond * time.Duration(conditionCheckMilliseconds))
    defer ticker.Stop()

    tick := func() error {
        fmt.Printf(".")
        if esc, err := escape(); esc || err != nil {
            fmt.Println("Escape!")
            close(doneC)
            return err
        }

        for _, f := range conditions {
            if ok, err := f(); ! ok || err != nil {
                return err
            }
        }
        ready = true
        close(doneC)
        return nil
    }

    for {
        select {
        case <- ticker.C:
            err = tick()
            if err != nil {
                close(doneC)
            }
        case <- doneC:
            _ = timer.Stop()
            return
        }
    }
}

// docker basic example expects one container named "basic", running crunchy-postgres\
func TestDockerBasic(t *testing.T) {
    const testName = "basic"
    const testInitTimeoutSeconds = 40

    buildBase := os.Getenv("BUILDBASE")
    if buildBase == "" {
        t.Fatal("Please set BUILDBASE environment variable to run tests.")
    }

    pathToTest := path.Join(
        buildBase, "examples", "docker", testName, "run.sh")
    pathToCleanup := path.Join(
        buildBase, "examples", "docker", testName, "cleanup.sh")

    // TestMinSupportedDockerVersion 1.18 seems to work fine?
    
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

    testCCPLabels(docker, c.ID, t)
    // count number of volumes
    // count number of mounts

    pgUserConStr, err := buildConnectionString(docker, c.ID, "postgres", "postgres")
    if err != nil {
        t.Fatal(err)
    }
    t.Log("Postgres User Connection String: " + pgUserConStr)

    fmt.Printf("Waiting for maximum %d seconds.\n", testInitTimeoutSeconds)

    /////////// allow container to start and db to initialize
    t.Logf("Waiting maximum %d seconds for container and postgres startup\n", testInitTimeoutSeconds)

    /////////// begin database tests
    var userName string = "testuser"
    var dbName string = "userdb"

    escape := func () (bool, error) {
        return isContainerDead(docker, c.ID)
    }
    condition1 := func () (bool, error) {
        if ok, err := isPostgresReady(docker, c.ID); ! ok || err != nil {
            return false, err
        }
        return isAcceptingConnectionString(pgUserConStr)
    }
    condition2 := func () (bool, error) {
        return roleExists(pgUserConStr, userName)
    }
    condition3 := func () (bool, error) {
        return dbExists(pgUserConStr, dbName)
    }
    if ok, err := timeoutOrReady(
        testInitTimeoutSeconds,
        escape,
        []func() (bool, error){condition1, condition2, condition3},
        500); err != nil {
        t.Error(err)
    } else if ! ok {
        t.Errorf("Container stopped; or timeout expired, and container is not ready.")
    }

    t.Run("Connect", func (t *testing.T) {
        if ok, err := isAcceptingConnectionString(pgUserConStr); err != nil {
            t.Fatal(err)
        } else if ! ok {
            t.Fail()
        }
    })
    t.Run("RoleExists", func (t *testing.T) {
        if ok, err := roleExists(pgUserConStr, userName); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("The %s ROLE was not created.\n", userName)
        }
    })
    t.Run("DatabaseExists", func (t *testing.T) {
        if ok, err := dbExists(pgUserConStr, dbName); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Error("The %s DATABASE was not created.\n", dbName)
        }
    })

    t.Run("CheckSharedBuffers", func (t *testing.T) {
        if ok, val, err := assertPostgresConf(
            pgUserConStr, "shared_buffers", "129MB"); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("shared_buffers is currently set to %s\n", val)
        }
    })

    t.Run("CanWriteToPostgresDb", func (t *testing.T) {
        if ok, err := relCreateInsertDrop(pgUserConStr); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Fail()
        }
    })

    // TestExtensionExists
    //  pg_stat_statements
    //  pgaudit

    // TestLocale en_US.UTF-8
    // assert lc_collate, lc_ctype

    ///////// test user
    userConStr, err := buildConnectionString(docker, c.ID, dbName, userName)
    if err != nil {
        t.Error(err)
    }
    t.Log("User Connection String: " + userConStr)

    t.Run("CheckUserCanCreateInsertDrop", func (t *testing.T) {
        if ok, err := relCreateInsertDrop(userConStr); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Fail()
        }
    })
    // // TestTempTable
 //    pg, err := sql.Open("postgres", pgUserConStr)
 //    if err != nil {
 //     t.Error(err)
 //    }
 //    q := fmt.Sprintf("REVOKE TEMPORARY on DATABASE %s from %s;",
 //     dbName, userName)
 //    if _, err := pg.Exec(q); err != nil {
 //     t.Error(err)
 //    }
 //    pg.Close()

 //    if _, err := tempTableCreateAndWrite(userConStr); err != nil {
 //     t.Error(err)
 //    }

    ///////// completed tests, cleanup
    t.Log("Calling cleanup" + pathToCleanup)
    cmdout, err = exec.Command(pathToCleanup).CombinedOutput()
    t.Logf("%s", cmdout)
    if err != nil {
        t.Fatal(err)
    }

    // test container is destroyed
    // test volume is destroyed
}


// Benchmark pgbench
