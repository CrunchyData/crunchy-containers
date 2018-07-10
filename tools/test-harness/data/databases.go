package data

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
