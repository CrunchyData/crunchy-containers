/*
 Copyright 2018 Crunchy Data Solutions, Inc.
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
    "testing"
)

func TestDockerBasic(t *testing.T) {

    // const exampleName = "basic"
    const timeoutSeconds = 60
    const skipCleanup = false

    buildBase := getBuildBase(t)

    // TestMinSupportedDockerAPIVersion 1.18 seems to work fine?
    
    docker := getDockerTestClient(t)
    defer docker.Close()

    /////////// docker is available, run the example
    containerId, cleanup := startBasic(t, docker, buildBase, timeoutSeconds)
    defer cleanup(skipCleanup)

    // verify labels match build
    t.Run("Labels", func (t *testing.T) {
        testLabels(t, docker, containerId)
    })

    // New Test: assert names and number of volumes

    // New Test: assert number of mounts

    // New Test: assert owner:group permissions on mounts

    pgConStr := conStrTestPostgres(t, docker, containerId)

    /////////// begin database tests

    t.Run("Connect", func (t *testing.T) {
        if ok, err := isAcceptingConnectionString(pgConStr); err != nil {
            t.Fatal(err)
        } else if ! ok {
            t.Errorf("Failed with connection string: %s\n", pgConStr)
        }
    })
    t.Run("RoleExists", func (t *testing.T) {
        if ok, err := roleExists(pgConStr, testuser); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("The %s ROLE was not created.\n", testuser)
        }
    })
    t.Run("DatabaseExists", func (t *testing.T) {
        if ok, err := dbExists(pgConStr, userdb); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("The %s DATABASE was not created.\n", userdb)
        }
    })

    // example postgresql.conf setting
    t.Run("CheckSharedBuffers", func (t *testing.T) {
        if ok, val, err := assertPostgresConf(
            pgConStr, "shared_buffers", "129MB"); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("shared_buffers is currently set to %s\n", val)
        }
    })

    t.Run("CanWriteToPostgresDb", func (t *testing.T) {
        if ok, err := relCreateInsertDrop(pgConStr, false); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Error("Write to database failed.")
        }
    })

    // TestExtensionExists
    //  pg_stat_statements
    //  pgaudit

    // TestLocale en_US.UTF-8
    // assert lc_collate, lc_ctype

    ///////// test user
    userConStr := conStrTestUser(t, docker, containerId)

    t.Run("CheckUserCanWrite", func (t *testing.T) {
        if ok, err := relCreateInsertDrop(userConStr, false); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Error("Failed to write to db: " + userConStr)
        }
    })

 //    pg, err := sql.Open("postgres", pgConStr)
 //    if err != nil {
 //     t.Error(err)
 //    }
 //    q := fmt.Sprintf("REVOKE TEMPORARY on DATABASE %s from %s;",
 //     dbName, userName)
 //    if _, err := pg.Exec(q); err != nil {
 //     t.Error(err)
 //    }
 //    pg.Close()

    t.Run("CheckUserCanWriteTEMP", func (t *testing.T) {
        if ok, err := relCreateInsertDrop(userConStr, true); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Error("Failed to create TEMPORARY table on db: " + userConStr)
        }
    })

    t.Log("All tests complete")
}

// Benchmark pgbench
