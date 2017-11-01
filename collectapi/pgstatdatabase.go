/*
 Copyright 2017 Crunchy Data Solutions, Inc.
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

func PgStatDatabaseMetrics(logger *log.Logger, dbs []string, HOSTNAME string, dbConn *sql.DB) []Metric {
	logger.Println("get pg_stat_database metrics")

	var metrics = make([]Metric, 0)

	var xact_commit, xact_rollback float64
	var tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted float64
	var conflicts, temp_files, temp_bytes, deadlocks float64
	var blks_read, blks_hit, blk_read_time, blk_write_time float64
	for i := 0; i < len(dbs); i++ {

		err := dbConn.QueryRow(
			"select xact_commit, xact_rollback, tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted, conflicts, temp_files, temp_bytes, deadlocks, blks_read, blks_hit, blk_read_time, blk_write_time  from pg_stat_database where datname = '"+dbs[i]+"'").Scan(
			&xact_commit, &xact_rollback,
			&tup_returned, &tup_fetched, &tup_inserted, &tup_updated,
			&tup_deleted, &conflicts, &temp_files, &temp_bytes,
			&deadlocks, &blks_read, &blks_hit,
			&blk_read_time, &blk_write_time)
		if err != nil {
			logger.Println("error: " + err.Error())
			return metrics
		}

		metric := NewMetric(HOSTNAME, "xact_commit", xact_commit)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "xact_rollback", xact_rollback)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "tup_returned", tup_returned)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "tup_fetched", tup_fetched)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "tup_inserted", tup_inserted)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "tup_updated", tup_updated)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "tup_deleted", tup_deleted)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "conflicts", conflicts)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "temp_files", temp_files)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "temp_bytes", temp_bytes)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "deadlocks", deadlocks)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "blks_read", blks_read)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "blks_hit", blks_hit)
		metric.AddLabel("Units", "count")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "hit_ratio", blks_hit/blks_read*100.0)
		metric.AddLabel("Units", "percent")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "blk_read_time", blk_read_time)
		metric.AddLabel("Units", "time")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)

		metric = NewMetric(HOSTNAME, "blk_write_time", blk_write_time)
		metric.AddLabel("Units", "time")
		metric.AddLabel("DatabaseName", dbs[i])
		metrics = append(metrics, metric)
	}

	return metrics

}
