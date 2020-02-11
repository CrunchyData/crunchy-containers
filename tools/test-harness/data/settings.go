package data

/*
Copyright 2018 - 2020 Crunchy Data Solutions, Inc.
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

// Setting is a data structure that holds the name and
// value of database settings.
type Setting struct {
	Name  string
	Value string
}

// Settings method returns all settings for the database.
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
