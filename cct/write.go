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
    "fmt"
    "testing"

    "github.com/docker/docker/client"

    _ "github.com/lib/pq"
)

func insertTestTable(
    t *testing.T,
    docker *client.Client,
    containerId string) (rowcount int64) {

    conStr := conStrTestUser(t, docker, containerId)

    pg, _ := sql.Open("postgres", conStr)

    table := fmt.Sprintf("%s.testtable", testuser)
    insert := `INSERT INTO ` + table + `(name, value, updatedt)
    SELECT substring(x.oid::text || y.oid::text for 30), x.relname, now()
      FROM pg_class as x CROSS JOIN pg_class as y;`
    
    result, err := pg.Exec(insert)
    if err != nil {
        t.Error(err)
    }

    rowcount, err = result.RowsAffected()
    if err != nil {
        t.Error(err)
    }
    t.Logf("Inserted %d rows\n", rowcount)

    return
}

type someTableFacts struct{
    rowcount int64
    relid int64
    relsize int64
}

func getFacts(
    docker *client.Client,
    containerId string,
    dbName string,
    tableName string) (facts someTableFacts, err error) {

    conStr, err := buildConnectionString(
        docker, containerId, dbName, "postgres")
    if err != nil {
        return
    }

    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := fmt.Sprintf(
    "SELECT count(*), '%[1]s'::regclass::oid, pg_relation_size('%[1]s'::regclass) from %[1]s;",
        tableName)

    err = pg.QueryRow(query).Scan(&facts.rowcount, &facts.relid, &facts.relsize)
    if err != nil {
        err = fmt.Errorf("Error on SELECT\n%s", err.Error())
        return
    }

    return
}

func writeSomeData(
    docker *client.Client,
    containerId string,
    dbName string) (facts someTableFacts, err error) {

    conStr, err := buildConnectionString(
        docker, containerId, dbName, "postgres")
    if err != nil {
        return
    }

    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    createTable := `CREATE TABLE some_table(
        some_id serial NOT NULL PRIMARY KEY, some_value text);`

    _, err = pg.Exec(createTable)
    if err != nil {
        err = fmt.Errorf("Error on EXEC CREATE TABLE\n%s", err.Error())
        return
    }

    insert := `INSERT INTO some_table(some_value)
        SELECT x.relname FROM pg_class as x CROSS JOIN pg_class as y;`

    result, err := pg.Exec(insert)
    if err != nil {
        err = fmt.Errorf("Error on EXEC INSERT\n%s", err.Error())
        return
    }

    facts.rowcount, err = result.RowsAffected()
    if err != nil {
        return
    }

    tablefacts := `SELECT 'some_table'::regclass::oid, pg_relation_size('some_table'::regclass);`

    err = pg.QueryRow(tablefacts).Scan(&facts.relid, &facts.relsize)
    if err != nil {
        return facts, fmt.Errorf("Error on SELECT tablefacts\n%s", err.Error())
    }

    return
}

func assertSomeData(
    docker *client.Client,
    containerId string,
    dbName string,
    facts someTableFacts) (ok bool, found someTableFacts, err error) {

    conStr, err := buildConnectionString(
        docker, containerId, dbName, "postgres")
    if err != nil {
        return
    }

    pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT count(*), pg_relation_size($1::regclass) from some_table;`

    err = pg.QueryRow(query, facts.relid).Scan(&found.rowcount, &found.relsize)
    if err != nil {
        return
    }

    ok = (facts.rowcount == found.rowcount && facts.relsize == found.relsize)
    return
}
