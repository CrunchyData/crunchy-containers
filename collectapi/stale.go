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

//get tables with stale statistics
func StaleTablesMetrics(logger *log.Logger, dbs []string, HOSTNAME string, USER string, PORT string, PASSWORD string, dbConn *sql.DB) []Metric {
	var metrics = make([]Metric, 0)
	for i := 0; i < len(dbs); i++ {

		d, err := GetMonitoringConnection(logger, HOSTNAME, USER, PORT, dbs[i], PASSWORD)
		if err != nil {
			logger.Println(err.Error())
			logger.Println("error getting db connection to " + dbs[i])
			return metrics
		}
		defer d.Close()

		var nspname, relname, kind string
		var last_vacuum, last_analyze string //pg date types
		var age int64

		rows, err2 := d.Query(
			" SELECT " +
				" nspname, " +
				" relname, " +
				" last_vacuum::text, " +
				" last_analyze::text, " +
				" age(relfrozenxid) " +
				" FROM " +
				" (SELECT " +
				" c.oid, " +
				" N.nspname, " +
				" C.relname, " +
				" date_trunc('day',greatest(pg_stat_get_last_vacuum_time(C.oid),pg_stat_get_last_autovacuum_time(C.oid)))::date AS last_vacuum, " +
				" date_trunc('day',greatest(pg_stat_get_last_analyze_time(C.oid),pg_stat_get_last_autoanalyze_time(C.oid)))::date AS last_analyze, " +
				" C.relfrozenxid " +
				" FROM pg_class C " +
				" LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) " +
				" WHERE C.relkind IN ('r', 't') AND " +
				" (NOT N.nspname IN ('pg_catalog', 'information_schema')) AND " +
				" N.nspname !~ '^pg_toast' AND " +
				" (greatest(pg_stat_get_last_analyze_time(C.oid),pg_stat_get_last_autoanalyze_time(C.oid)) IS NULL) OR (greatest(pg_stat_get_last_analyze_time(C.oid),pg_stat_get_last_autoanalyze_time(C.oid)) < (now() - '1 day'::interval - '1 hour'::interval)) " +
				" ) AS av " +
				" WHERE    (NOT nspname IN ('pg_catalog', 'information_schema')) " +
				" ORDER BY last_analyze NULLS FIRST ")
		if err2 != nil {
			logger.Println("error: " + err.Error())
			return metrics
		}
		defer rows.Close()

		for rows.Next() {
			if err = rows.Scan(
				&nspname, &relname, &kind,
				&last_vacuum, &last_analyze,
				&age); err != nil {
				logger.Println("error: " + err.Error())
				return metrics
			}

			metric := Metric{}
			metric.Hostname = HOSTNAME
			metric.MetricName = "stale_age"
			metric.Units = "count"
			metric.Value = age
			metric.LastVacuum = last_vacuum
			metric.LastAnalyze = last_analyze
			metric.DatabaseName = dbs[i]
			metric.TableName = relname
			metrics = append(metrics, metric)
		}

	}

	return metrics
}
