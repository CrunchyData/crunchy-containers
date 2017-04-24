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
    "context"
    "database/sql"
    "fmt"
    "path"
    "strings"
    "time"

    "github.com/docker/docker/api/types"
    "github.com/docker/docker/client"

    _ "github.com/lib/pq"
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
    pb := inspect.HostConfig.PortBindings
    if pb == nil || len(pb) == 0 {
        err = fmt.Errorf(
            "Container network in an incomplete state; no PortBindings\n%#v\n",
            inspect.HostConfig)
        return
    }
    binding := inspect.HostConfig.PortBindings["5432/tcp"][0]

    host, port = binding.HostIP, binding.HostPort
    return
}

func isShutdownErr(err error) bool {
    return strings.HasPrefix(string(err.Error()),
        "pq: the database system is shutting down")
}

func isPasswordErr(err error) bool {
    return strings.HasPrefix(string(err.Error()),
        "pq: password authentication failed")
}

func isReadOnlyErr(err error) bool {
    return strings.HasSuffix(string(err.Error()),
        "pq: cannot execute CREATE TABLE in a read-only transaction")
}

func isAcceptingConnectionString(conStr string) (bool, error) {
    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    err := pg.Ping()
    if err != nil {
        switch {
        case isShutdownErr(err):
            return false, nil
        case isPasswordErr(err):
            return false, nil
        default:
            return false, fmt.Errorf(
                "Ping error; the connection string is not ok\n%s\n\n%s\n",
                    conStr, err.Error())
        }
    }

    return true, nil
}

// returns ok when container_setup script is not running
func isFinishedSetup(conStr string) (ok bool, err error) {
    ok = false
    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT NOT EXISTS (
        SELECT 1 from pg_stat_activity
        WHERE application_name = 'container_setup');`

    err = pg.QueryRow(query).Scan(&ok)
    if err != nil {
        return
    }

    return
}

// returns pg_is_in_backup()
func isInBackup(conStr string) (ok bool, err error) {
    ok = false
    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    err = pg.QueryRow("SELECT pg_is_in_backup();").Scan(&ok)
    if err != nil {
        return
    }

    return
}

// assert a configurable parameter is set to value 
func assertPostgresConf(
    conStr string, 
    setting string, 
    value string) (ok bool, foundval string, err error) {

    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    // SHOW command does not support $1 style variable replacement
    show := fmt.Sprintf("SHOW %s;", setting)

    err = pg.QueryRow(show).Scan(&foundval)
    if err != nil {
        return
    }

    ok = (foundval == value)
    return
}

// streams some vital columns from pg_stat_activity in tab form as they are retrieved
func pgStatActivity(conStr string) error {

    type activityrow struct {
        Pid int64 `json:"pid"`
        Database string `json:"database"`
        User string `json:"user"`
        ApplicationName string `json:"application_name"`
        State string `json:"state"`
        WaitEventType string `json:"wait_event_type"`
        WaitEvent string `json:"wait_event"`
        Query string `json:"query"`
        StartTime time.Time `json:"backend_start"`
    }

    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT pid, datname, usename, application_name
        , state, coalesce(wait_event_type, ''), coalesce(wait_event, ''), query, backend_start
        from pg_stat_activity WHERE pid != pg_backend_pid();`

    rows, err := pg.Query(query)
    if err != nil {
        return err
    }

    for rows.Next() {
        var r activityrow
        err = rows.Scan(&r.Pid, &r.Database, &r.User, &r.ApplicationName, 
            &r.State, &r.WaitEventType, &r.WaitEvent, &r.Query, &r.StartTime)
        if err != nil {
            return err
        }
        fmt.Printf("%+v\n", r)
    }

    return nil
}

// returns ok if a manual VACUUM (not AUTOVACUUM) is in progress
func isVacuuming(conStr string) (ok bool, err error) {
    ok = false
    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT EXISTS (SELECT * from pg_stat_activity WHERE query like 'VACUUM%');`
    err = pg.QueryRow(query).Scan(&ok)
    if err != nil {
        return
    }

    return
}

func waitForVacuum(
    conStr string,
    timeoutSeconds int64) (err error) {

    fmt.Printf("Waiting maximum %d seconds for VACUUM", timeoutSeconds)

    condition1 := func() (bool, error) {
        v, err := isVacuuming(conStr)
        return ! v, err
    }
    var pollingMilliseconds int64 = 500
    if ok, err := timeoutOrReady(
        timeoutSeconds,
        no_escape,
        []func() (bool, error){condition1},
        pollingMilliseconds); err != nil {
        return err
    } else if ! ok {
        return fmt.Errorf("Timeout expired and VACUUM has not finished")
    }

    return
}

// print some basics on table vacuum & analyze
func pgTableStat(conStr string, tableName string) error {

    type tablestatrow struct {
        Relid int64 `json:"relid"`
        SchemaName string `json:"schemaname"`
        RelName string `json:"relname"`
        RowEstimate int64 `json:"row_estimate"`
        LastVacuum time.Time `json:"last_vacuum"`
        LastAnalyze time.Time `json:"last_analyze"`
        VacuumCount int64 `json:"vacuum_count"`
        AnalyzeCount int64 `json:"analyze_count"`
    }

    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT relid, schemaname, relname, n_live_tup
        , coalesce(last_vacuum, '2000-01-01'), coalesce(last_analyze, '2000-01-01')
        , vacuum_count, analyze_count
        FROM pg_stat_all_tables WHERE relname = $1;`

    rows, err := pg.Query(query, tableName)
    if err != nil {
        return err
    }

    for rows.Next() {
        var r tablestatrow
        err = rows.Scan(&r.Relid, &r.SchemaName, &r.RelName, &r.RowEstimate, 
            &r.LastVacuum, &r.LastAnalyze, &r.VacuumCount, &r.AnalyzeCount)
        if err != nil {
            return err
        }
        fmt.Printf("%+v\n", r)
    }

    return nil
}

// CREATE, INSERT INTO, DROP TABLE
func relCreateInsertDrop(conStr string, temporary bool) (ok bool, err error) {
    ok = false

    pg, _ := sql.Open("postgres", conStr)
    
    defer pg.Close()

    var create string
    if temporary {
        create = "CREATE TEMPORARY TABLE"
    } else {
        create = "CREATE TABLE"
    }
    create += ` some_table(some_id integer NOT NULL PRIMARY KEY);`
    insert := `INSERT INTO some_table(some_id) VALUES(1), (2), (3);`
    drop := `DROP TABLE some_table;`

    _, err = pg.Exec(create)
    if err != nil {
        err = fmt.Errorf("ON CREATE TABLE\n%s", err.Error())
        return
    }

    if result, e := pg.Exec(insert); e != nil {
        err = fmt.Errorf("ON INSERT\n%s", e.Error())
        return
    } else {
        rc, e := result.RowsAffected();
        if e != nil || rc != 3 {
            err = fmt.Errorf(
                "Error or rowcount mismatch. Expected rc 3, got %d\n%s", rc, e.Error())
            return
        }
    }
    _, err = pg.Exec(drop)
    if err != nil {
        err = fmt.Errorf("ON DROP TABLE\n%s", err.Error())
        return
    }

    ok = true
    return
}

// does role exist on specified host?
func roleExists(conStr string, roleName string) (ok bool, err error) {
    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT EXISTS (SELECT 1 from pg_roles WHERE rolname = $1);`

    err = pg.QueryRow(query, roleName).Scan(&ok)
    if err != nil {
        return
    }

    return
}

// does database exist on specified host?
func dbExists(conStr string, dbName string) (ok bool, err error) {
    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT EXISTS (SELECT 1 from pg_database WHERE datname = $1);`

    err = pg.QueryRow(query, dbName).Scan(&ok)
    if err != nil {
        return
    }

    return
}

// wraps pg_isready via docker exec
func isPostgresReady(
    docker *client.Client,
    containerId string) (bool, error) {

    pgroot, err := envValueFromContainer(docker, containerId, "PGROOT")
    if err != nil {
        return false, fmt.Errorf("Could not get PGROOT\n%s", err.Error())
    }    
    cmd := []string{path.Join(pgroot, "bin/pg_isready"), "-h", "/tmp"}

    execConf := types.ExecConfig{
        User: "postgres",
        Detach: true,
        Cmd: cmd,
    }
    execId, err := docker.ContainerExecCreate(
        context.Background(), containerId, execConf)
    if err != nil {
        return false, err
    }

    err = docker.ContainerExecStart(
        context.Background(), execId.ID, types.ExecStartCheck{})
    if err != nil {
        return false, err
    }

    // allow pg_isready to complete

    var ok = false
    doneC := make(chan bool, 1)

    ticker := time.NewTicker(time.Millisecond * 10)
    defer ticker.Stop()

    tick := func(ok *bool) error {
        inspect, err := docker.ContainerExecInspect(
            context.Background(), execId.ID)
        if inspect.Running {
            fmt.Printf(">")
            return nil
        } else if err != nil {
            return err
        }

        *ok = (inspect.ExitCode == 0)
        close(doneC)
        return nil
    }

    for {
        select {
        case <- ticker.C:
            err = tick(&ok)
            if err != nil {
                close(doneC)
            }
        case <- time.After(3 * time.Second):
            err = fmt.Errorf("%s timed out after 3 seconds\n", cmd[0])
            close(doneC)
        case <- doneC:
            return ok, err
        }
    }
}

// Performs checks to see if Postgres container is ready to start:
// - Container is running
// - pg_isready responds
// - 
// - setup SQL script has completed
func waitForPostgresContainer(
    docker *client.Client,
    name string,
    timeoutSeconds int64) (containerId string, err error) {

    if c, err := ContainerFromName(docker, name); err != nil {
        return "", err
    } else {
        containerId = c.ID
    }

    conStr, err := buildConnectionString(docker, containerId, "postgres", "postgres")
    if err != nil {
        return "", fmt.Errorf("Connection String error\n%s\n", err.Error())
    }

    escape := func () (bool, error) {
        return isContainerDead(docker, containerId)
    }
    condition1 := func () (bool, error) {
        // fmt.Printf("A")
        return isContainerRunning(docker, containerId)
    }
    condition2 := func () (bool, error) {
        // fmt.Printf("B")
        return isPostgresReady(docker, containerId)
    }
    condition3 := func () (bool, error) {
        // fmt.Printf("C")
        return isAcceptingConnectionString(conStr)
    }
    condition4 := func () (bool, error) {
        // fmt.Printf("D")
        return isFinishedSetup(conStr)
    }

    var ok bool
    var pollingMilliseconds int64 = 500
    if ok, err = timeoutOrReady(
        timeoutSeconds,
        escape,
        []func() (bool, error){condition1, condition2, condition3, condition4},
        pollingMilliseconds); 
    err != nil {
        return
    } else if ! ok {
        now := time.Now()
        return containerId, 
            fmt.Errorf("%s: Container stopped; or timeout expired, and container is not ready.",
                now.Format("2006-01-02 15:04:05.000"))
    }

    // the container receives a stop at the end of setup. Make sure we haven't missed this, and let the db start again if we have.
    time.Sleep(1 * time.Second)

    ok, err = timeoutOrReady(
        10, escape,
        []func() (bool, error) {condition1, condition2, condition3},
        pollingMilliseconds)
    if err != nil {
        return
    } else if ! ok {
        return containerId, fmt.Errorf("Container stopped; or timeout expired, and container is not ready.")
    }

    return
}

// Helper for timeoutOrReady calls where no escape condition is required
func no_escape() (bool, error) {
    return false, nil
}

// Waits maximum of timeout seconds, or passes when all conditions are true, or will escape if escape function returns true. Returns false if timeout expired without meeting conditions.
func timeoutOrReady(
    timeoutSeconds int64,
    escape func() (bool, error),
    conditions []func() (bool, error),
    pollingIntervalMilliseconds int64) (bool, error) {

    timeoutDuration := time.Second * time.Duration(timeoutSeconds)
    pollDuration := time.Millisecond * time.Duration(pollingIntervalMilliseconds)

    doneC := make(chan bool, 1)

    ticker := time.NewTicker(pollDuration)
    defer ticker.Stop()

    tick := func(ready *bool) error {
        fmt.Printf(".")
        if esc, err := escape(); err != nil {
            return err
        } else if esc {
            return fmt.Errorf("Escape condition met!\n")
        }

        for i, f := range conditions {
            if ok, err := f(); err != nil {
                err = fmt.Errorf("\nError from function %d\n%s", i, err.Error())
            } else if !ok {
                return nil
            }
        }

        fmt.Printf("\n")
        *ready = true
        close(doneC)
        return nil
    }

    var ready = false
    var err error

    for {
        select {
        case <- ticker.C:
            err = tick(&ready)
            if err != nil {
                close(doneC)
            }
        case <- time.After(timeoutDuration):
            ready = false
            err = fmt.Errorf("Timeout expired after %v\n", timeoutDuration)
            close(doneC)
        case <- doneC:
            return ready, err
        }
    }
}
