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

import "database/sql"

// Database is a structure that holds the name of
// databases.
type Database struct {
	Name string
}

// Databases returns all databases.
func (db *DB) Databases() ([]Database, error) {
	statement := "SELECT datname FROM pg_database WHERE datistemplate = false"

	rows, err := db.Query(statement)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	dbs := []Database{}
	for rows.Next() {
		var dbname sql.NullString
		if err := rows.Scan(&dbname); err != nil {
			return nil, err
		}
		d := Database{
			Name: dbname.String,
		}
		dbs = append(dbs, d)
	}
	return dbs, nil
}
