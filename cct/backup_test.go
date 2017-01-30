package cct

import (
    "bufio"
    "context"
    "database/sql"
    "fmt"
    // "io/ioutil"
    "path"
    "strings"
    "testing"
    "time"

    "github.com/docker/docker/client"
    "github.com/docker/docker/api/types"
    "github.com/docker/docker/api/types/container"
    "github.com/docker/docker/api/types/network"
    "github.com/docker/docker/api/types/strslice"

    _ "github.com/lib/pq"
)

type someTableFacts struct{
    rowcount int64
    relid int64
    relsize int64
}

func writeSomeData(
    docker *client.Client,
    containerId string) (facts someTableFacts, err error) {

    conStr, err := buildConnectionString(
        docker, containerId, "postgres", "postgres")
    if err != nil {
        return
    }

    pg, err := sql.Open("postgres", conStr)
    if err != nil {
        return
    }
    defer pg.Close()

    createTable := `CREATE TABLE some_table(
        some_id serial NOT NULL PRIMARY KEY, some_value text);`

    _, err = pg.Exec(createTable)
    if err != nil {
        fmt.Println("ON EXEC CREATE")
        return
    }

    insert := `INSERT INTO some_table(some_value)
        SELECT x.relname FROM pg_class as x CROSS JOIN pg_class as y;`

    result, err := pg.Exec(insert)
    if err != nil {
        fmt.Println("ON EXEC INSERT")
        return
    }

    facts.rowcount, err = result.RowsAffected()
    if err != nil {
        return
    }

    tablefacts := `SELECT 'some_table'::regclass::oid, pg_relation_size('some_table'::regclass);`

    err = pg.QueryRow(tablefacts).Scan(&facts.relid, &facts.relsize)
    if err != nil {
        return
    }

    return
}

func assertSomeData(
    docker *client.Client,
    containerId string,
    rowcount int64) (ok bool, foundrc int64, err error) {

    conStr, err := buildConnectionString(
        docker, containerId, "postgres", "postgres")
    if err != nil {
        return
    }

    pg, err := sql.Open("postgres", conStr)
    if err != nil {
        return
    }
    defer pg.Close()

    err = pg.QueryRow("SELECT count(*) from some_table;").Scan(&foundrc)
    if err != nil {
        return
    }

    ok = (rowcount == foundrc)
    return
}

func waitForBackup(
    docker *client.Client,
    containerId string,
    timeoutSeconds int64) (ok bool, err error) {

    ok = false

    conStr, err := buildConnectionString(
        docker, containerId, "postgres", "postgres")
    if err != nil {
        return
    }

    doneC := make(chan bool)
    timer := time.AfterFunc(time.Second * time.Duration(timeoutSeconds), func () {
        close(doneC)
    })
    ticker := time.NewTicker(time.Millisecond * 100)

    tick := func () error {
        if isrun, err := isContainerRunning(docker, containerId); err != nil {
            return err
        } else if ! isrun {
            close(doneC)
        }
        if bkup, err := isInBackup(conStr); err != nil {
            return err
        } else if ! bkup {
            ok = true
            close(doneC)
        }
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

func statBackupLabel(
    docker *client.Client,
    containerId string,
    backup string) (ok bool, err error) {

    stat, err := docker.ContainerStatPath(
        context.Background(),
        containerId,
        path.Join("/pgdata/basic-backups", backup, "backup_label"))
    if err != nil {
        if strings.HasPrefix(string(err.Error()),
            "Error: request returned Not Found") {
            ok, err = false, nil
            return
        }
        return
    }
    fmt.Println(stat)

    ok = (stat.Size > 0)
    return
}

// starts a container that takes volumes-from fromContainerName (a backup container)
// returns 
func getBackupName(
    docker *client.Client,
    fromContainerName string,
    localBackupPath string) (ok bool, name string, err error) {

    conf := container.Config{
        User: "postgres",
        Cmd: strslice.StrSlice{"-t", localBackupPath},
        Entrypoint: strslice.StrSlice{"ls"},
        Image: "crunchy-backup",
    }
    hostConf := container.HostConfig{
        VolumeDriver: "local",
        VolumesFrom: strslice.StrSlice{fromContainerName},
    }

    c, err := docker.ContainerCreate(
        context.Background(),
        &conf,
        &hostConf,
        &network.NetworkingConfig{}, 
        "ls-backup")
    if err != nil {
        return
    }
    // fmt.Println("created ls-backup; warnings: ", c.Warnings)

    defer func () {
        if e := docker.ContainerRemove(
            context.Background(),
            c.ID,
            types.ContainerRemoveOptions{
                RemoveVolumes: true,
                Force: true,
            }); e != nil {
            err = e
        }
    } ()

    err = docker.ContainerStart(context.Background(), c.ID, types.ContainerStartOptions{})
    if err != nil {
        return
    }

    logReader, err := docker.ContainerLogs(
        context.Background(),
        c.ID,
        types.ContainerLogsOptions{
            ShowStdout: true,
            ShowStderr: true,
            Follow: true,
            Details: true,
        })
    defer logReader.Close()
    if err != nil {
        return
    }

    // read the first line from the docker log (result of ls -t /pgdata/basic-backups)
    scanner := bufio.NewScanner(logReader)

    ok = scanner.Scan()
    if ! ok {
        err = scanner.Err()
        return
    }
    name = scanner.Text()

    name = strings.TrimLeft(name,
        string([]byte{1, 0, 0, 0, 0, 0, 0, 21, 32}))

    // ok, err = statBackupLabel(docker, c.ID, name)
    ok = true

    return
}

// docker basic example expects one container named "basic", running crunchy-postgres\
func TestDockerBackupRestore(t *testing.T) {
    const exampleName = "backup"
    const exampleTimeoutSeconds = 90

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    var basicTimeout int64 = 60
    basicCleanup, basicId, err := startBasic(
        docker, buildBase, basicTimeout, t)

    defer basicCleanup(false)
    // fmt.Printf("Waiting maximum %d seconds to start basic example", basicTimeout)
    // /////////// docker is available; run basic, then backup
    // t.Log("Starting Example: docker/basic")
    // basicCleanup, cmdout, err := startDockerExample(buildBase, "basic")
    // if err != nil {
    //     t.Fatal(err, cmdout)
    // }
    // basicId, err := waitForPostgresContainer(docker, "basic", basicTimeout)
    // t.Log("Started basic container: ", basicId)


    t.Log("Write some data to basic container to test backup / restore")
    facts, err := writeSomeData(docker, basicId)
    if err != nil {
        t.Error(err)
    }
    t.Log(facts)

    /////////// basic has started, run backup
    t.Log("Starting Example: docker/" + exampleName)
    pathToCleanup, cmdout, err := startDockerExample(buildBase, exampleName)
    if err != nil {
    	t.Fatal(err, cmdout)
    }

    c, err := ContainerFromName(docker, "basicbackup")
    if err != nil {
        return
    }
    containerId := c.ID
    t.Log("Started basicbackup container: ", containerId)

    // verify labels match build
    t.Run("BackupContainer", func (t *testing.T) {
        testCCPLabels(docker, containerId, t)
    })

    // wait for backup to finish on basic container
    ok, err := waitForBackup(docker, basicId, exampleTimeoutSeconds)
    if err != nil {
        t.Fatal(err)
    } else if ! ok {
        t.Fatalf("Backup did not complete after %n seconds.\n", exampleTimeoutSeconds)
    }

    var backupName string
    t.Run("CheckBackup", func (t *testing.T) {
        ok, name, err := getBackupName(docker, "basicbackup", "/pgdata/basic-backups")
        if name == "" {
            t.Fatal("No backup found in basicbackup container.")
        }
        if err != nil {
            t.Log("Got backup name: " + name)
            t.Fatal(err)
        }
        t.Log("Created backup: " + name)
        backupName = name
        if ! ok {
            t.Fatal("File not found in backup path.")
        }
    })
    if t.Failed() {
        t.Fatal("Cannot procede")
    }

    t.Log("Starting restore")
    var restoreId, restoreCleanup string
    t.Run("Restore", func(t *testing.T) {
        cleanup, cmdout, err := startDockerExample(buildBase, "restore", backupName)
        if err != nil {
            t.Error(err, cmdout)
        }
        restoreCleanup = cleanup

        fmt.Println("Waiting for master-restore container to start")
        restoreId, err = waitForPostgresContainer(docker, "master-restore", 60)
        if err != nil {
            t.Error(err)
        }
    })

    t.Run("CheckRestoreData", func(t *testing.T) {
        if ok, rc, err := assertSomeData(
            docker, restoreId, facts.rowcount); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("Restore failed, expected %n, counted %n\n", facts.rowcount, rc)
        }
    })

    t.Log("NOT Cleaning up backup: ", pathToCleanup)
    // ///////// completed tests, cleanup
    // t.Log("Cleaning up backup: ", pathToCleanup)
    // cmdout, err = cleanupExample(pathToCleanup)
    // if err != nil {
    //     t.Error(err, cmdout)
    // }
    // t.Log(cmdout)

    t.Log("NOT Cleaning up basic: ", basicCleanup)
    // // cleanup basic container
    // t.Log("Cleaning up basic: ", basicCleanup)
    // cmdout, err = cleanupExample(basicCleanup)
    // if err != nil {
    //     t.Error(err, cmdout)
    // }
    // t.Log(cmdout)

    t.Log("NOT cleaning up restore: ", restoreCleanup)
    // // cleanup master-restore container
    // t.Log("Cleaning up restore: ", restoreCleanup)
    // cmdout, err = cleanupExample(restoreCleanup)
    // if err != nil {
    //     t.Error(err, cmdout)
    // }
    // t.Log(cmdout)

    t.Log("All tests complete")
}
