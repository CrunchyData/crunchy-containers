/*
 Copyright 2018 Crunchy Data Solutions, Inc.
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

	var checkpoints_timed, checkpoints_req float64
	var checkpoint_write_time, checkpoint_sync_time float64
	var buffers_checkpoint, buffers_clean, maxwritten_clean float64
	var buffers_backend, buffers_backend_fsync, buffers_alloc float64

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

	metric := NewMetric(HOSTNAME, "checkpoints_time", checkpoints_timed)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "checkpoints_req", checkpoints_req)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "checkpoint_write_time", checkpoint_write_time)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "checkpoint_sync_time", checkpoint_sync_time)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "buffers_checkpoint", buffers_checkpoint)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "buffers_clean", buffers_clean)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "maxwritten_clean", maxwritten_clean)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "buffers_backend", buffers_backend)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "buffers_backend_fsync", buffers_backend_fsync)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	metric = NewMetric(HOSTNAME, "buffers_alloc", buffers_alloc)
	metric.AddLabel("Units", "count")
	metric.AddLabel("DatabaseName", "cluster")
	metrics = append(metrics, metric)

	return metrics

}
