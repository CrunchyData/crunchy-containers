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
	"log"
	//_ "github.com/lib/pq"
)

//get tables with dead rows
func DeadRowsMetrics(logger *log.Logger, dbs []string, HOSTNAME string, USER string, PORT string, PASSWORD string, dbConn *sql.DB) []Metric {
	logger.Println("DeadRowsMetrics")
	var metrics = make([]Metric, 0)
	for i := 0; i < len(dbs); i++ {

		d, err := GetMonitoringConnection(logger, HOSTNAME, USER, PORT, dbs[i], PASSWORD)
		if err != nil {
			logger.Println(err.Error())
			logger.Println("error getting db connection to " + dbs[i])
			return metrics
		}
		defer d.Close()

		var nspname, relname string
		var n_dead_tup, reltuples, table_sz, total_sz int64
		var last_vacuum, last_analyze string //pg date types
		var av_needed string
		var pct_dead int64
		rows, err := d.Query(
			"SELECT" +
				" nspname," +
				" relname,n_dead_tup::numeric," +
				" reltuples::numeric," +
				" pg_relation_size(oid)/1024/1024 as table_sz," +
				" pg_total_relation_size(oid)/1024/1024 as total_sz," +
				" last_vacuum," +
				" last_analyze," +
				" n_dead_tup > av_threshold AS av_needed," +
				" CASE WHEN reltuples > 0" +
				" 	THEN round(100.0 * n_dead_tup / (reltuples))" +
				" 	ELSE 0" +
				" 		END" +
				" 			AS pct_dead" +
				" 	FROM" +
				" 	(SELECT" +
				" 		c.oid," +
				" 		N.nspname," +
				" 		C.relname," +
				" 		pg_stat_get_tuples_inserted(C.oid) AS n_tup_ins," +
				" 		pg_stat_get_tuples_updated(C.oid) AS n_tup_upd," +
				" 		pg_stat_get_tuples_deleted(C.oid) AS n_tup_del," +
				" 		pg_stat_get_live_tuples(C.oid) AS n_live_tup," +
				" 		pg_stat_get_dead_tuples(C.oid) AS n_dead_tup," +
				" 		C.reltuples AS reltuples," +
				" 		round(current_setting('autovacuum_vacuum_threshold')::integer" +
				" 		+ current_setting('autovacuum_vacuum_scale_factor')::numeric * C.reltuples)" +
				" 		AS av_threshold," +
				" 		date_trunc('day',greatest(pg_stat_get_last_vacuum_time(C.oid),pg_stat_get_last_autovacuum_time(C.oid)))::date AS last_vacuum," +
				" 		date_trunc('day',greatest(pg_stat_get_last_analyze_time(C.oid),pg_stat_get_last_analyze_time(C.oid)))::date AS last_analyze" +
				" 	FROM pg_class C" +
				" 		LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)" +
				" 	WHERE C.relkind IN ('r', 't')" +
				" 	AND N.nspname NOT IN ('pg_catalog', 'information_schema') AND" +
				" 	N.nspname !~ '^pg_toast'" +
				" ) AS av" +
				" WHERE n_dead_tup > 100000" +
				" ORDER BY n_dead_tup DESC")
		if err != nil {
			logger.Println("error: " + err.Error())
			return metrics
		}
		defer rows.Close()

		for rows.Next() {
			if err = rows.Scan(
				&nspname, &relname,
				&n_dead_tup, &reltuples, &table_sz, &total_sz,
				&last_vacuum, &last_analyze,
				&av_needed, &pct_dead); err != nil {
				logger.Println("error: " + err.Error())
				return metrics
			}

			metric := Metric{}
			metric.Hostname = HOSTNAME
			metric.MetricName = "pct_dead"
			metric.Units = "item"
			metric.Value = pct_dead
			metric.DeadTup = n_dead_tup
			metric.RelTup = reltuples
			metric.TableSz = table_sz
			metric.TotalSz = total_sz
			metric.LastVacuum = last_vacuum
			metric.LastAnalyze = last_analyze
			metric.AvNeeded = av_needed
			metric.DatabaseName = dbs[i]
			metric.TableName = relname
			metrics = append(metrics, metric)
		}

	}

	return metrics
}
