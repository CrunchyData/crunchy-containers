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

//get tables that are approaching a wraparound
func WraparoundMetrics(logger *log.Logger, dbs []string, HOSTNAME string, USER string, PORT string, PASSWORD string, dbConn *sql.DB) []Metric {
	var metrics = make([]Metric, 0)
	for i := 0; i < len(dbs); i++ {

		d, err := GetMonitoringConnection(logger, HOSTNAME, USER, PORT, dbs[i], PASSWORD)
		if err != nil {
			logger.Println(err.Error())
			logger.Println("error getting db connection to " + dbs[i])
			return metrics
		}
		defer d.Close()

		var nspname, relname, kind, age string
		var table_sz, total_sz int64
		var last_vacuum string //pg date types
		rows, err2 := d.Query(
			" SELECT  " +
				" nspname, " +
				" CASE WHEN relkind='t' THEN toastname ELSE relname END AS relname, " +
				" CASE WHEN relkind='t' THEN 'Toast' ELSE 'Table' END AS kind, " +
				" (pg_relation_size(oid)/1024/1024) as table_sz, " +
				" (pg_total_relation_size(oid)/1024/1024) as total_sz, " +
				" age(relfrozenxid)::text, " +
				" last_vacuum " +
				" FROM " +
				" (SELECT " +
				" c.oid, " +
				" c.relkind, " +
				" N.nspname, " +
				" C.relname, " +
				" T.relname AS toastname, " +
				" C.relfrozenxid, " +
				" date_trunc('day',greatest(pg_stat_get_last_vacuum_time(C.oid),pg_stat_get_last_autovacuum_time(C.oid)))::date AS last_vacuum, " +
				" setting::integer as freeze_max_age " +
				" FROM pg_class C " +
				" LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) " +
				" LEFT OUTER JOIN pg_class T ON (C.oid=T.reltoastrelid), " +
				" pg_settings " +
				" WHERE C.relkind IN ('r', 't') " +
				" AND N.nspname NOT IN ('pg_catalog', 'information_schema') AND " +
				" name='autovacuum_freeze_max_age' " +
				" AND pg_relation_size(c.oid)>0 " +
				" ) AS av " +
				" WHERE age(relfrozenxid) > (0.85 * freeze_max_age) " +
				" ORDER BY age(relfrozenxid) DESC, pg_total_relation_size(oid) DESC")
		if err2 != nil {
			logger.Println("error: " + err.Error())
			return metrics
		}
		defer rows.Close()

		for rows.Next() {
			if err = rows.Scan(
				&nspname, &relname, &kind,
				&table_sz, &total_sz,
				&age, &last_vacuum); err != nil {
				logger.Println("error: " + err.Error())
				return metrics
			}

			metric := Metric{}
			metric.Hostname = HOSTNAME
			metric.MetricName = "wraparound"
			metric.Units = "item"
			metric.Value = 1
			metric.Kind = kind
			metric.TableSz = table_sz
			metric.TotalSz = total_sz
			metric.LastVacuum = last_vacuum
			metric.Age = age
			metric.DatabaseName = dbs[i]
			metric.TableName = relname
			metrics = append(metrics, metric)
		}

	}

	return metrics
}
