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

// Extension is a data structure that holds information
// about extensions found in the database.
type Extension struct {
	DefaultVersion   string
	InstalledVersion string
	Name             string
}

/// AllExtensions method returns all extensions available.
func (db *DB) AllExtensions() ([]Extension, error) {
	statement := "SELECT name, default_version, installed_version " +
		" FROM pg_available_extensions"

	rows, err := db.Query(statement)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	extensions := []Extension{}
	for rows.Next() {
		var name, defaultVersion, installedVersion sql.NullString
		if err := rows.Scan(&name, &defaultVersion, &installedVersion); err != nil {
			return nil, err
		}
		x := Extension{
			Name:             name.String,
			DefaultVersion:   defaultVersion.String,
			InstalledVersion: installedVersion.String,
		}
		extensions = append(extensions, x)
	}
	return extensions, nil
}

// InstalledExtensions method returns all installed extensions in the
// database currently being queried.
func (db *DB) InstalledExtensions() ([]Extension, error) {
	statement := "SELECT name, default_version, installed_version " +
		" FROM pg_available_extensions WHERE installed_version IS NOT NULL"

	rows, err := db.Query(statement)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	extensions := []Extension{}
	for rows.Next() {
		var name, defaultVersion, installedVersion sql.NullString
		if err := rows.Scan(&name, &defaultVersion, &installedVersion); err != nil {
			return nil, err
		}
		x := Extension{
			Name:             name.String,
			DefaultVersion:   defaultVersion.String,
			InstalledVersion: installedVersion.String,
		}
		extensions = append(extensions, x)
	}
	return extensions, nil
}
