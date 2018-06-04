package data

import (
	"database/sql"
)

type Setting struct {
	Name  string
	Value string
}

func (db *DB) Settings() ([]Setting, error) {
	statement := "SELECT name, setting FROM pg_settings"
	rows, err := db.Query(statement)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	settings := []Setting{}
	for rows.Next() {
		var name, value sql.NullString
		if err := rows.Scan(&name, &value); err != nil {
			return nil, err
		}
		s := Setting{
			Name:  name.String,
			Value: value.String,
		}
		settings = append(settings, s)
	}
	return settings, nil
}
