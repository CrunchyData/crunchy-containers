package data

import (
	"database/sql"
)

// Replication is a data structure that holds replication
// state queried from the primary database.
type Replication struct {
	Name      string
	State     string
	SentLSN   string
	WriteLSN  string
	ReplayLSN string
	SyncState string
}

// Replication returns the state of replicas from the primary.
func (db *DB) Replication() ([]Replication, error) {
	statement := "SELECT application_name, state, sent_lsn, " +
		"write_lsn, replay_lsn, sync_state FROM pg_catalog.pg_stat_replication"

	rows, err := db.Query(statement)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	replication := []Replication{}
	for rows.Next() {
		var name, state, sent, write, replay, syncState sql.NullString
		if err := rows.Scan(&name, &state, &sent, &write, &replay, &syncState); err != nil {
			return nil, err
		}
		r := Replication{
			Name:      name.String,
			State:     state.String,
			SentLSN:   sent.String,
			WriteLSN:  write.String,
			ReplayLSN: replay.String,
			SyncState: syncState.String,
		}
		replication = append(replication, r)
	}
	return replication, nil
}
