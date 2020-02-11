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

// Role is a data structure that describes the roles
// found in the database.
type Role struct {
	Name        string
	Super       bool
	Inherit     bool
	CreateRole  bool
	CreateDB    bool
	Login       bool
	ConnLimit   int
	Replication bool
	BypassRLS   bool
}

// Roles method returns all the roles found in the database.
func (db *DB) Roles() ([]Role, error) {
	statement := `
SELECT
  r.rolname, r.rolsuper, r.rolinherit,
  r.rolcreaterole, r.rolcreatedb, r.rolcanlogin,
  r.rolconnlimit, r.rolreplication, r.rolbypassrls
FROM pg_catalog.pg_roles r
WHERE r.rolname !~ '^pg_' ORDER BY 1
`

	rows, err := db.Query(statement)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	roles := []Role{}
	for rows.Next() {
		r := Role{}
		if err := rows.Scan(&r.Name, &r.Super,
			&r.Inherit, &r.CreateRole, &r.CreateDB, &r.Login,
			&r.ConnLimit, &r.Replication, &r.BypassRLS); err != nil {
			return nil, err
		}

		roles = append(roles, r)
	}
	return roles, nil
}
