package data

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
