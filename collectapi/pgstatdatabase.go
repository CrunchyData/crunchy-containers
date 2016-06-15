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

func PgStatDatabaseMetrics(logger *log.Logger, dbs []string, HOSTNAME string, dbConn *sql.DB) []Metric {
	logger.Println("get pg_stat_database metrics")

	var metrics = make([]Metric, 0)

	var xact_commit, xact_rollback int64
	var tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted int64
	var conflicts, temp_files, temp_bytes, deadlocks int64
	var blks_read, blks_hit, blk_read_time, blk_write_time int64
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

		metric := Metric{}
		metric.Hostname = HOSTNAME
		metric.MetricName = "xact_commit"
		metric.Units = "count"
		metric.Value = xact_commit
		metric.DatabaseName = dbs[i]
		metrics = append(metrics, metric)

		metric2 := Metric{}
		metric2.Hostname = HOSTNAME
		metric2.MetricName = "xact_rollback"
		metric2.Units = "count"
		metric2.Value = xact_rollback
		metric2.DatabaseName = dbs[i]
		metrics = append(metrics, metric2)

		metric3 := Metric{}
		metric3.Hostname = HOSTNAME
		metric3.MetricName = "tup_returned"
		metric3.Units = "count"
		metric3.Value = tup_returned
		metric3.DatabaseName = dbs[i]
		metrics = append(metrics, metric3)

		metric4 := Metric{}
		metric4.Hostname = HOSTNAME
		metric4.MetricName = "tup_fetched"
		metric4.Units = "count"
		metric4.Value = tup_fetched
		metric4.DatabaseName = dbs[i]
		metrics = append(metrics, metric4)

		metric5 := Metric{}
		metric5.Hostname = HOSTNAME
		metric5.MetricName = "tup_inserted"
		metric5.Units = "count"
		metric5.Value = tup_inserted
		metric5.DatabaseName = dbs[i]
		metrics = append(metrics, metric5)

		metric6 := Metric{}
		metric6.Hostname = HOSTNAME
		metric6.MetricName = "tup_updated"
		metric6.Units = "count"
		metric6.Value = tup_updated
		metric6.DatabaseName = dbs[i]
		metrics = append(metrics, metric6)

		metric7 := Metric{}
		metric7.Hostname = HOSTNAME
		metric7.MetricName = "tup_deleted"
		metric7.Units = "count"
		metric7.Value = tup_deleted
		metric7.DatabaseName = dbs[i]
		metrics = append(metrics, metric7)

		metric8 := Metric{}
		metric8.Hostname = HOSTNAME
		metric8.MetricName = "conflicts"
		metric8.Units = "count"
		metric8.Value = conflicts
		metric8.DatabaseName = dbs[i]
		metrics = append(metrics, metric8)

		metric9 := Metric{}
		metric9.Hostname = HOSTNAME
		metric9.MetricName = "temp_files"
		metric9.Units = "count"
		metric9.Value = temp_files
		metric9.DatabaseName = dbs[i]
		metrics = append(metrics, metric9)

		metric10 := Metric{}
		metric10.Hostname = HOSTNAME
		metric10.MetricName = "temp_bytes"
		metric10.Units = "count"
		metric10.Value = temp_bytes
		metric10.DatabaseName = dbs[i]
		metrics = append(metrics, metric10)

		metric11 := Metric{}
		metric11.Hostname = HOSTNAME
		metric11.MetricName = "deadlocks"
		metric11.Units = "count"
		metric11.Value = deadlocks
		metric11.DatabaseName = dbs[i]
		metrics = append(metrics, metric11)

		metric12 := Metric{}
		metric12.Hostname = HOSTNAME
		metric12.MetricName = "blks_read"
		metric12.Units = "count"
		metric12.Value = blks_read
		metric12.DatabaseName = dbs[i]
		metrics = append(metrics, metric12)

		metric13 := Metric{}
		metric13.Hostname = HOSTNAME
		metric13.MetricName = "blks_hit"
		metric13.Units = "count"
		metric13.Value = blks_hit
		metric13.DatabaseName = dbs[i]
		metrics = append(metrics, metric13)

		metric14 := Metric{}
		metric14.Hostname = HOSTNAME
		metric14.MetricName = "hit_ratio"
		metric14.Units = "percent"
		metric14.Value = int64(float64(blks_hit) / float64(blks_read) * 100.0)
		metric14.DatabaseName = dbs[i]
		metrics = append(metrics, metric14)

		metric15 := Metric{}
		metric15.Hostname = HOSTNAME
		metric15.MetricName = "blk_read_time"
		metric15.Units = "time"
		metric15.Value = blk_read_time
		metric15.DatabaseName = dbs[i]
		metrics = append(metrics, metric15)

		metric16 := Metric{}
		metric16.Hostname = HOSTNAME
		metric16.MetricName = "blk_write_time"
		metric16.Units = "time"
		metric16.Value = blk_write_time
		metric16.DatabaseName = dbs[i]
		metrics = append(metrics, metric16)
	}

	return metrics

}
