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
    "database/sql"
    "testing"
    // "time"

    _ "github.com/lib/pq"
)

func TestDockerVacuum(t *testing.T) {

    // const exampleName = "vacuum"
    const timeoutSeconds = 60
    const skipCleanup = false

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    basicId, basicCleanup := startBasic(t, docker, buildBase, timeoutSeconds)
    defer basicCleanup(skipCleanup)

    conStr, err := buildConnectionString(
        docker, basicId, userdb, testuser)
    if err != nil {
        t.Fatal(err)
    }

    // generate some write activity
    if err = writeAndDelete(conStr);
    err != nil {
        t.Fatal(err)
    }

    // writeAndDelete function creates this table
    var tablename = "write_delete_table"

    cleanup := startDockerExampleForTest(t, buildBase, "vacuum", tablename)
    defer cleanup(skipCleanup)

    // // discard vacuum containerId, we will not need it again.
    // _ = testContainerNoVersion(t, "VacuumContainer", docker, "vacuum")
    // if t.Failed() {
    //     t.Fatal("Cannot proceed")
    // }

    // VACUUM FULL does NOT update the last_vacuum field of pg_stat_user_tables
    // But, example runs VACUUM FULL ANALYZE so use last_analyze instead. 
    t.Run("CheckVacuum", func(t *testing.T) {

        if err := waitForVacuum(conStr, timeoutSeconds); err != nil {
            t.Fatal(err)
        }

        pg, _ := sql.Open("postgres", conStr)
        defer pg.Close()

        query := `SELECT t.last_analyze is NOT NULL from pg_stat_all_tables as t
            WHERE t.relname = $1;`

        var ok bool
        if err := pg.QueryRow(query, tablename).Scan(&ok); err != nil {
            t.Error(err)
        }
        if ! ok {
            t.Errorf("VACUUM FULL ANALYZE %s did not occur\n", tablename)
        }
    })

    t.Log("All tests complete")
}
