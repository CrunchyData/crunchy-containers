package cct

import (
    "context"
    "database/sql"
    "fmt"
    "io/ioutil"
    "os"
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

func writeSomeData(
    docker *client.Client,
    containerId string) (rowcount int64, err error) {

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

    createTable := `CREATE TABLE public.some_table(
        some_id serial NOT NULL PRIMARY KEY, some_value text);`

    _, err = pg.Exec(createTable)
    if err != nil {
        return
    }

    insert := `INSERT INTO public.some_table(some_value)
        SELECT x.relname FROM pg_class as x CROSS JOIN pg_class as y;`

    result, err := pg.Exec(insert)
    if err != nil {
        return
    }

    rowcount, err = result.RowsAffected()
    if err != nil {
        return
    }

    // should get table size

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

    err = pg.QueryRow("SELECT count(*) from public.some_table;").Scan(&foundrc)
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

// starts a container that takes volumes-from fromContainerName (a backup container)
// returns 
func getBackupName(
    docker *client.Client,
    fromContainerName string,
    localBackupPath string) (name string, err error) {


    conf := container.Config{
        User: "postgres",
        Cmd: strslice.StrSlice{localBackupPath},
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
    fmt.Println("created ls-backup; warnings: ", c.Warnings)

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

    content, err := ioutil.ReadAll(logReader)
    if err != nil {
        return
    }

    // fmt.Println(content[:])
    name = strings.TrimLeft(
        strings.TrimRight(string(content[:]), "\n"),
        string([]byte{1, 0, 0, 0, 0, 0, 0, 21, 32}))

    return
}

// docker basic example expects one container named "basic", running crunchy-postgres\
func TestDockerBackupRestore(t *testing.T) {
    const exampleName = "backup"
    const exampleTimeoutSeconds = 90

    buildBase := os.Getenv("BUILDBASE")
    if buildBase == "" {
    	t.Fatal("Please set BUILDBASE environment variable to run tests.")
    }

    t.Log("Initializing docker client")
    docker, err := client.NewEnvClient()
    if err != nil {
        t.Fatal(err)
    }

    defer docker.Close()

    /////////// docker is available; run basic, then backup
    t.Log("Starting Example: docker/basic")
    basicCleanup, cmdout, err := startDockerExample(buildBase, "basic")
    if err != nil {
        t.Fatal(err, cmdout)
    }
    basicId, err := waitForPostgresContainer(docker, "basic", 60)
    t.Log("Started basic container: ", basicId)


    t.Log("Write some data to basic container to test backup / restore")
    rowcount, err := writeSomeData(docker, basicId)
    if err != nil {
        t.Error(err)
    }

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
    testCCPLabels(docker, containerId, t)

    // wait for backup to finish on basic container
    ok, err := waitForBackup(docker, basicId, exampleTimeoutSeconds)
    if err != nil {
        t.Fatal(err)
    } else if ! ok {
        t.Fatalf("Backup did not complete after %n seconds.\n", exampleTimeoutSeconds)
    }

    // we will test the backup by trying to restore
    name, err := getBackupName(docker, "basicbackup", "/pgdata/basic")
    if err != nil {
        t.Fatal(err)
    }
    if name == "" {
        t.Fatalf("No backup found in basicbackup container.")
    }

    var restoreCleanup string
    t.Run("Restore", func(t *testing.T) {
        t.Log("Starting restore")
        cleanup, cmdout, err := startDockerExample(buildBase, "restore", name)
        if err != nil {
            t.Error(err, cmdout)
        }
        restoreCleanup = cleanup
    })

    c, err = ContainerFromName(docker, "master-restore")
    if err != nil {
        t.Error(err)
    }
    restoreId := c.ID

    // pause for restore / pg startup

    t.Run("CheckRestoreData", func(t *testing.T) {
        if ok, rc, err := assertSomeData(
            docker, restoreId, rowcount); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("Restore failed, expected %n, counted %n\n", rowcount, rc)
        }
    })

    ///////// completed tests, cleanup
    t.Log("Cleaning up backup: ", pathToCleanup)
    cmdout, err = cleanupExample(pathToCleanup)
    if err != nil {
        t.Error(err, cmdout)
    }
    t.Log(cmdout)

    // cleanup basic container
    t.Log("Cleaning up basic: ", basicCleanup)
    cmdout, err = cleanupExample(basicCleanup)
    if err != nil {
        t.Error(err, cmdout)
    }
    t.Log(cmdout)

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
