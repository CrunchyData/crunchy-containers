package cct

import (
    "context"
    "database/sql"
    "path"
    "strings"
    "time"

    "github.com/docker/docker/api/types"
    "github.com/docker/docker/client"

    _ "github.com/lib/pq"
)

import (
    "fmt"
    "reflect"
)

// returns the HostIP and Port reported by the service on 5432/tcp, which should always be postgresql
func pgHostFromContainer(
    docker *client.Client, 
    containerId string) (host string, port string, err error) {

    inspect, err := docker.ContainerInspect(
        context.Background(), containerId)
    if err != nil {
        return
    }
    binding := inspect.HostConfig.PortBindings["5432/tcp"][0]

    host, port = binding.HostIP, binding.HostPort
    return
}

// wraps pg_isready via docker exec
func isPostgresReady(
    docker *client.Client,
    containerId string) (ok bool, err error) {

    ok = false

    pgroot, err := envValueFromContainer(docker, containerId, "PGROOT")
    if err != nil {
        return
    }    
    cmd := []string{path.Join(pgroot, "bin/pg_isready")}

    execConf := types.ExecConfig{
        User: "postgres",
        Detach: true,
        Cmd: cmd,
    }
    execId, err := docker.ContainerExecCreate(
        context.Background(), containerId, execConf)
    if err != nil {
        return
    }

    err = docker.ContainerExecStart(
        context.Background(), execId.ID, types.ExecStartCheck{})
    if err != nil {
        return
    }

    // allow pg_isready 1 second to complete; or return false
    doneC := make(chan bool)
    timer := time.AfterFunc(time.Second, func() {
        close(doneC)
    })

    ticker := time.NewTicker(time.Millisecond * 100)
    defer ticker.Stop()

    tick := func() (bool, error) {
        inspect, err := docker.ContainerExecInspect(
            context.Background(), execId.ID)

        if inspect.Running || err != nil {
            return false, err
        }

        close(doneC)
        return (inspect.ExitCode == 0), nil
    }
    for {
        select {
        case <- ticker.C:
            ok, err = tick()
        case <- doneC:
            _ = timer.Stop()
            return
        }
    }
}

// returns false on password error (err for all others)
func isAcceptingConnectionString(conStr string) (ok bool, err error) {
    ok = false
    pg, err := sql.Open("postgres", conStr)
    if err != nil {
        return
    }
    defer pg.Close()

    err = pg.Ping()
    if err != nil {
        if strings.HasPrefix(string(err.Error()),
            "pq: password authentication failed") {
            return false, nil
        }
        return
    }

    ok = true
    return
}

// returns ok when container_setup script is not running
func isFinishedSetup(conStr string) (ok bool, err error) {
    ok = false
    pg, err := sql.Open("postgres", conStr)
    if err != nil {
        return
    }
    defer pg.Close()

    query := `SELECT NOT EXISTS (
        SELECT 1 from pg_stat_activity
        WHERE state <> 'idle' and application_name = 'container_setup');`

    err = pg.QueryRow(query).Scan(&ok)
    if err != nil {
        return
    }

    return
}

// returns pg_is_in_backup()
func isInBackup(conStr string) (ok bool, err error) {
    ok = false
    pg, err := sql.Open("postgres", conStr)
    if err != nil {
        return
    }
    defer pg.Close()

    err = pg.QueryRow("SELECT pg_is_in_backup();").Scan(&ok)
    if err != nil {
        return
    }

    return
}

// can create and write to temp table?
func tempTableCreateAndWrite(conStr string) (ok bool, err error) {
    pg, err := sql.Open("postgres", conStr)
    if err != nil {
        return
    }
    defer pg.Close()

    result, err := pg.Exec("CREATE TEMPORARY TABLE some_table(some_id integer);")
    if err != nil {
        return
    }
    fmt.Println("here it is ", reflect.TypeOf(result), reflect.ValueOf(result))

    return true, nil
}

// CREATE, INSERT INTO, DROP TABLE
func relCreateInsertDrop(conStr string) (ok bool, err error) {
    ok = false

    pg, err := sql.Open("postgres", conStr)
    if err != nil {
        return
    }

    _, err = pg.Exec("CREATE TABLE some_table(some_id integer NOT NULL PRIMARY KEY);")
    if err != nil {
        return
    }

    result, err := pg.Exec("INSERT INTO some_table(some_id) VALUES(1), (2), (3);")
    if err != nil {
        return
    }

    rc, err := result.RowsAffected()
    if err != nil || rc != 3 {
        return
    }

    _, err = pg.Exec("DROP TABLE some_table;")
    if err != nil {
        return
    }

    ok = true
    return
}

// does role exist on specified host?
func roleExists(conStr string, roleName string) (ok bool, err error) {
    pg, err := sql.Open("postgres", conStr)
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
func dbExists(conStr string, dbName string) (ok bool, err error) {
    pg, err := sql.Open("postgres", conStr)
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

