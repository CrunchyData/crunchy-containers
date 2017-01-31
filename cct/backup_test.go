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
    const timeoutSeconds = 90
    const skipCleanup = true

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    var basicTimeout int64 = 60
    basicCleanup, basicId := startBasic(
        t, docker, buildBase, basicTimeout)

    defer basicCleanup(skipCleanup)

    t.Log("Write some data to basic container to test backup / restore")
    facts, err := writeSomeData(docker, basicId)
    if err != nil {
        t.Error(err)
    }
    t.Log(facts)

    /////////// basic has started, run backup
    backupCleanup := startDockerExampleForTest(t, buildBase, exampleName)
    defer backupCleanup(skipCleanup)

    var containerId string
    if t.Run("StartBackupContainer", func (t *testing.T) {
        c, err := ContainerFromName(docker, "basicbackup")
        if err != nil {
            t.Fatal(err)
        }
        containerId = c.ID
        t.Log("Started basicbackup container: ", containerId)
    }); t.Failed() {
        t.Fatal("Cannot proceed")
    }

    // verify labels match build
    t.Run("Container", func (t *testing.T) {
        testCCPLabels(docker, containerId, t)
    })

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
            t.Fatal("No backup found in basicbackup container.")
        } else if err != nil {
            t.Log("Got backup name: " + name)
            t.Fatal(err)
        } else if ! ok {
            t.Log("Got backup name: " + name)
            t.Fatal("File not found in backup path.")
        } else {
            backupName = name
        }

        t.Log("Created backup: " + backupName)

    }); t.Failed() {
        t.Fatal("Cannot proceed")
    }

    fmt.Println("HEY! Pause 60 seconds before restore!?")
    time.Sleep(60 * time.Second)

    t.Log("Starting restore")
    var restoreId string
    var restoreCleanup func (skip bool)
    t.Run("Restore", func(t *testing.T) {
        restoreCleanup = startDockerExampleForTest(t, buildBase, "restore", backupName)

        fmt.Println("Waiting for master-restore container to start")
        restoreId, err = waitForPostgresContainer(docker, "master-restore", 60)
        if err != nil {
            t.Error(err)
        }
    })
    defer restoreCleanup(skipCleanup)

    t.Run("CheckRestoreData", func(t *testing.T) {
        if ok, rc, err := assertSomeData(
            docker, restoreId, facts.rowcount); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("Restore failed, expected %n, counted %n\n", facts.rowcount, rc)
        }
    })

    t.Log("All tests complete")
}
