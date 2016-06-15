/*
 Copyright 2016 Crunchy Data Solutions, Inc.
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

package collectapi

import (
	"database/sql"
	_ "github.com/lib/pq"
	"log"
)

func GetMetrics(logger *log.Logger, HOSTNAME string, USER string, PORT string, PASS string, conn *sql.DB) ([]Metric, error) {
	var err error
	dbs := GetDatabases(logger, conn)
	metrics := GetConnectionMetrics(logger, HOSTNAME, conn)
	metric := GetConnectionUtilMetrics(logger, HOSTNAME, conn)
	metrics = append(metrics, *metric)
	sizeMetrics := GetDatabaseSizeMetrics(logger, dbs, HOSTNAME, conn)
	for i := 0; i < len(sizeMetrics); i++ {
		metrics = append(metrics, sizeMetrics[i])
	}
	statMetrics := PgStatDatabaseMetrics(logger, dbs, HOSTNAME, conn)
	for i := 0; i < len(statMetrics); i++ {
		metrics = append(metrics, statMetrics[i])
	}
	bgwriterMetrics := BgwriterMetrics(logger, HOSTNAME, conn)
	for i := 0; i < len(bgwriterMetrics); i++ {
		metrics = append(metrics, bgwriterMetrics[i])
	}
	lockMetrics := LockMetrics(logger, dbs, HOSTNAME, conn)
	for i := 0; i < len(lockMetrics); i++ {
		metrics = append(metrics, lockMetrics[i])
	}
	tableSizeMetrics := TableSizesMetrics(logger, dbs, HOSTNAME, USER, PORT, PASS, conn)
	for i := 0; i < len(tableSizeMetrics); i++ {
		metrics = append(metrics, tableSizeMetrics[i])
	}
	deadRowMetrics := DeadRowsMetrics(logger, dbs, HOSTNAME, USER, PORT, PASS, conn)
	for i := 0; i < len(deadRowMetrics); i++ {
		metrics = append(metrics, deadRowMetrics[i])
	}
	xlogMetrics := XlogCountMetrics(logger, HOSTNAME, conn)
	for i := 0; i < len(xlogMetrics); i++ {
		metrics = append(metrics, xlogMetrics[i])
	}
	return metrics, err
}

func PrintMetrics(logger *log.Logger, metrics []Metric) error {
	var err error
	logger.Println("writing metrics")
	for i := 0; i < len(metrics); i++ {
		metrics[i].Print()
	}
	return err
}

func GetMonitoringConnection(logger *log.Logger, dbHost string, dbUser string, dbPort string, database string, dbPassword string) (*sql.DB, error) {

	var dbConn *sql.DB
	var err error

	if dbPassword == "" {
		logger.Println("a open db with dbHost=[" + dbHost + "] dbUser=[" + dbUser + "] dbPort=[" + dbPort + "] database=[" + database + "]")
		dbConn, err = sql.Open("postgres", "sslmode=disable user="+dbUser+" host="+dbHost+" port="+dbPort+" dbname="+database)
	} else {
		logger.Println("b open db with dbHost=[" + dbHost + "] dbUser=[" + dbUser + "] dbPort=[" + dbPort + "] database=[" + database + "] password=[" + dbPassword + "]")
		dbConn, err = sql.Open("postgres", "sslmode=disable user="+dbUser+" host="+dbHost+" port="+dbPort+" dbname="+database+" password="+dbPassword)
	}
	if err != nil {
		logger.Println("error in getting connection :" + err.Error())
	}
	return dbConn, err
}

func GetDatabases(logger *log.Logger, dbConn *sql.DB) []string {
	logger.Println("get databases")

	var dbs = make([]string, 0)
	var rows *sql.Rows
	var err error

	rows, err = dbConn.Query("select datname from pg_database where datname NOT LIKE 'template%'")
	if err != nil {
		logger.Println("error: " + err.Error())
		return dbs
	}
	defer rows.Close()

	var dbname string

	for rows.Next() {
		if err = rows.Scan(&dbname); err != nil {
			logger.Println("error:" + err.Error())
			return dbs
		}

		dbs = append(dbs, dbname)

	}
	return dbs

}
