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

	metric := NewPGMetric(HOSTNAME, "checkpoints_time")
	metric.SetValue(checkpoints_timed)
	metric.Units = "count"
	metric.DatabaseName = "cluster"
	metrics = append(metrics, metric)

	metric2 := NewPGMetric(HOSTNAME, "checkpoints_req")
	metric2.SetValue(checkpoints_req)
	metric2.Units = "count"
	metric2.DatabaseName = "cluster"
	metrics = append(metrics, metric2)

	metric3 := NewPGMetric(HOSTNAME, "checkpoint_write_time")
	metric3.SetValue(checkpoint_write_time)
	metric3.Units = "count"
	metric3.DatabaseName = "cluster"
	metrics = append(metrics, metric3)

	metric4 := NewPGMetric(HOSTNAME, "checkpoint_sync_time")
	metric4.SetValue(checkpoint_sync_time)
	metric4.Units = "count"
	metric4.DatabaseName = "cluster"
	metrics = append(metrics, metric4)

	metric5 := NewPGMetric(HOSTNAME, "buffers_checkpoint")
	metric5.SetValue(buffers_checkpoint)
	metric5.Units = "count"
	metric5.DatabaseName = "cluster"
	metrics = append(metrics, metric5)

	metric6 := NewPGMetric(HOSTNAME, "buffers_clean")
	metric6.SetValue(buffers_clean)
	metric6.Units = "count"
	metric6.DatabaseName = "cluster"
	metrics = append(metrics, metric6)

	metric7 := NewPGMetric(HOSTNAME, "maxwritten_clean")
	metric7.SetValue(maxwritten_clean)
	metric7.Units = "count"
	metric7.DatabaseName = "cluster"
	metrics = append(metrics, metric7)

	metric8 := NewPGMetric(HOSTNAME, "buffers_backend")
	metric8.SetValue(buffers_backend)
	metric8.Units = "count"
	metric8.DatabaseName = "cluster"
	metrics = append(metrics, metric8)

	metric9 := NewPGMetric(HOSTNAME, "buffers_backend_fsync")
	metric9.SetValue(buffers_backend_fsync)
	metric9.Units = "count"
	metric9.DatabaseName = "cluster"
	metrics = append(metrics, metric9)

	metric10 := NewPGMetric(HOSTNAME, "buffers_alloc")
	metric10.SetValue(buffers_alloc)
	metric10.Units = "count"
	metric10.DatabaseName = "cluster"
	metrics = append(metrics, metric10)

	return metrics

}
