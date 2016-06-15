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

func BgwriterMetrics(logger *log.Logger, HOSTNAME string, dbConn *sql.DB) []Metric {
	logger.Println("get pg_stat_bgwriter metrics")

	var metrics = make([]Metric, 0)

	var checkpoints_timed, checkpoints_req int64
	var checkpoint_write_time, checkpoint_sync_time int64
	var buffers_checkpoint, buffers_clean, maxwritten_clean int64
	var buffers_backend, buffers_backend_fsync, buffers_alloc int64

	err := dbConn.QueryRow(
		"select checkpoints_timed, checkpoints_req, checkpoint_write_time, checkpoint_sync_time, buffers_checkpoint, buffers_clean, maxwritten_clean, buffers_backend, buffers_backend_fsync, buffers_alloc from pg_stat_bgwriter").Scan(
		&checkpoints_timed, &checkpoints_req,
		&checkpoint_write_time, &checkpoint_sync_time,
		&buffers_checkpoint, &buffers_clean, &maxwritten_clean,
		&buffers_backend, &buffers_backend_fsync, &buffers_alloc)
	if err != nil {
		logger.Println("error: " + err.Error())
		return metrics
	}

	metric := Metric{}
	metric.Hostname = HOSTNAME
	metric.MetricName = "checkpoints_timed"
	metric.Units = "count"
	metric.Value = checkpoints_timed
	metric.DatabaseName = "cluster"
	metrics = append(metrics, metric)

	metric2 := Metric{}
	metric2.Hostname = HOSTNAME
	metric2.MetricName = "checkpoints_req"
	metric2.Units = "count"
	metric2.Value = checkpoints_req
	metric2.DatabaseName = "cluster"
	metrics = append(metrics, metric2)

	metric3 := Metric{}
	metric3.Hostname = HOSTNAME
	metric3.MetricName = "checkpoint_write_time"
	metric3.Units = "count"
	metric3.Value = checkpoint_write_time
	metric3.DatabaseName = "cluster"
	metrics = append(metrics, metric3)

	metric4 := Metric{}
	metric4.Hostname = HOSTNAME
	metric4.MetricName = "checkpoint_sync_time"
	metric4.Units = "count"
	metric4.Value = checkpoint_sync_time
	metric4.DatabaseName = "cluster"
	metrics = append(metrics, metric4)

	metric5 := Metric{}
	metric5.Hostname = HOSTNAME
	metric5.MetricName = "buffers_checkpoint"
	metric5.Units = "count"
	metric5.Value = buffers_checkpoint
	metric5.DatabaseName = "cluster"
	metrics = append(metrics, metric5)

	metric6 := Metric{}
	metric6.Hostname = HOSTNAME
	metric6.MetricName = "buffers_clean"
	metric6.Units = "count"
	metric6.Value = buffers_clean
	metric6.DatabaseName = "cluster"
	metrics = append(metrics, metric6)

	metric7 := Metric{}
	metric7.Hostname = HOSTNAME
	metric7.MetricName = "maxwritten_clean"
	metric7.Units = "count"
	metric7.Value = maxwritten_clean
	metric7.DatabaseName = "cluster"
	metrics = append(metrics, metric7)

	metric8 := Metric{}
	metric8.Hostname = HOSTNAME
	metric8.MetricName = "buffers_backend"
	metric8.Units = "count"
	metric8.Value = buffers_backend
	metric8.DatabaseName = "cluster"
	metrics = append(metrics, metric8)

	metric9 := Metric{}
	metric9.Hostname = HOSTNAME
	metric9.MetricName = "buffers_backend_fsync"
	metric9.Units = "count"
	metric9.Value = buffers_backend_fsync
	metric9.DatabaseName = "cluster"
	metrics = append(metrics, metric9)

	metric10 := Metric{}
	metric10.Hostname = HOSTNAME
	metric10.MetricName = "buffers_alloc"
	metric10.Units = "count"
	metric10.Value = buffers_alloc
	metric10.DatabaseName = "cluster"
	metrics = append(metrics, metric10)

	return metrics

}
