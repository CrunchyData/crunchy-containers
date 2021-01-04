package data

/*
Copyright 2018 - 2021 Crunchy Data Solutions, Inc.
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

import (
	"database/sql"
)

// Replication is a data structure that holds replication
// state queried from the primary database.
type Replication struct {
	Name      string
	State     string
	SyncState string
}

// Replication returns the state of replicas from the primary.
func (db *DB) Replication() ([]Replication, error) {
	statement := "SELECT application_name, state, " +
		"sync_state FROM pg_catalog.pg_stat_replication"

	rows, err := db.Query(statement)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	replication := []Replication{}
	for rows.Next() {
		var name, state, syncState sql.NullString
		if err := rows.Scan(&name, &state, &syncState); err != nil {
			return nil, err
		}
		r := Replication{
			Name:      name.String,
			State:     state.String,
			SyncState: syncState.String,
		}
		replication = append(replication, r)
	}
	return replication, nil
}
