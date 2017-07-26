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

		metric := NewPGMetric(HOSTNAME, "xact_commit")
		metric.Units = "count"
		metric.SetValue(xact_commit)
		metric.DatabaseName = dbs[i]
		metrics = append(metrics, metric)

		metric2 := NewPGMetric(HOSTNAME, "xact_rollback")
		metric2.Units = "count"
		metric2.SetValue(xact_rollback)
		metric2.DatabaseName = dbs[i]
		metrics = append(metrics, metric2)

		metric3 := NewPGMetric(HOSTNAME, "tup_returned")
		metric3.Units = "count"
		metric3.SetValue(tup_returned)
		metric3.DatabaseName = dbs[i]
		metrics = append(metrics, metric3)

		metric4 := NewPGMetric(HOSTNAME, "tup_fetched")
		metric4.Units = "count"
		metric4.SetValue(tup_fetched)
		metric4.DatabaseName = dbs[i]
		metrics = append(metrics, metric4)

		metric5 := NewPGMetric(HOSTNAME, "tup_inserted")
		metric5.Units = "count"
		metric5.SetValue(tup_inserted)
		metric5.DatabaseName = dbs[i]
		metrics = append(metrics, metric5)

		metric6 := NewPGMetric(HOSTNAME, "tup_updated")
		metric6.Units = "count"
		metric6.SetValue(tup_updated)
		metric6.DatabaseName = dbs[i]
		metrics = append(metrics, metric6)

		metric7 := NewPGMetric(HOSTNAME, "tup_deleted")
		metric7.Units = "count"
		metric7.SetValue(tup_deleted)
		metric7.DatabaseName = dbs[i]
		metrics = append(metrics, metric7)

		metric8 := NewPGMetric(HOSTNAME, "conflicts")
		metric8.Units = "count"
		metric8.SetValue(conflicts)
		metric8.DatabaseName = dbs[i]
		metrics = append(metrics, metric8)

		metric9 := NewPGMetric(HOSTNAME, "temp_files")
		metric9.Units = "count"
		metric9.SetValue(temp_files)
		metric9.DatabaseName = dbs[i]
		metrics = append(metrics, metric9)

		metric10 := NewPGMetric(HOSTNAME, "temp_bytes")
		metric10.Units = "count"
		metric10.SetValue(temp_bytes)
		metric10.DatabaseName = dbs[i]
		metrics = append(metrics, metric10)

		metric11 := NewPGMetric(HOSTNAME, "deadlocks")
		metric11.Units = "count"
		metric11.SetValue(deadlocks)
		metric11.DatabaseName = dbs[i]
		metrics = append(metrics, metric11)

		metric12 := NewPGMetric(HOSTNAME, "blks_read")
		metric12.Units = "count"
		metric12.SetValue(blks_read)
		metric12.DatabaseName = dbs[i]
		metrics = append(metrics, metric12)

		metric13 := NewPGMetric(HOSTNAME, "blks_hit")
		metric13.Units = "count"
		metric13.SetValue(blks_hit)
		metric13.DatabaseName = dbs[i]
		metrics = append(metrics, metric13)

		metric14 := NewPGMetric(HOSTNAME, "hit_ratio")
		metric14.Units = "percent"
		metric14.SetValue(blks_hit / blks_read * 100.0)
		metric14.DatabaseName = dbs[i]
		metrics = append(metrics, metric14)

		metric15 := NewPGMetric(HOSTNAME, "blk_read_time")
		metric15.Units = "time"
		metric15.SetValue(blk_read_time)
		metric15.DatabaseName = dbs[i]
		metrics = append(metrics, metric15)

		metric16 := NewPGMetric(HOSTNAME, "blk_write_time")
		metric16.Units = "time"
		metric16.SetValue(blk_write_time)
		metric16.DatabaseName = dbs[i]
		metrics = append(metrics, metric16)
	}

	return metrics

}
