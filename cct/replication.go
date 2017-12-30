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
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)

// run against primary container host. Returns true when pg_stat_replication shows a state of "streaming" for the example replica
func isReplicationStarted(conStr string) (ok bool, err error) {

	pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT EXISTS (SELECT 1 from pg_stat_replication
    	WHERE application_name = 'replica' and state = 'streaming');`

    err = pg.QueryRow(query).Scan(&ok)
    if err != nil {
    	return
    }

    return
}

// pg_stat_replication sent_location = replay_location?
func replSentEqReplay(conStr string) (ok bool, err error) {

	pg, _ := sql.Open("postgres", conStr)
    defer pg.Close()

    query := `SELECT (sent_location = replay_location) from pg_stat_replication 
    	WHERE application_name='replica' and state='streaming';`

    err = pg.QueryRow(query).Scan(&ok)
    if err != nil {
    	return
    }

    return
}

// allow maximum of timeoutSeconds for streaming replication to replay, as measured from PRIMARY host pg_stat_replication
func waitForReplay(
	conStr string,
	timeoutSeconds int64) (err error) {

    fmt.Printf("Waiting maximum of %d seconds for replay", timeoutSeconds)

    escape := func() (bool, error) {
    	// unknown failure if irs is false
    	irs, err := isReplicationStarted(conStr)
    	return ! irs, err
    }
    condition1 := func() (bool, error) {
    	return replSentEqReplay(conStr)
    }
    var pollingMilliseconds int64 = 500
    if ok, err := timeoutOrReady(
    	timeoutSeconds,
        escape,
        []func() (bool, error){condition1},
        pollingMilliseconds); err != nil {
        return err
    } else if ! ok {
        return fmt.Errorf("Replication stopped; or timeout expired, and replay has not completed.")
    }

    return
}
