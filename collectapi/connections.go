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

func GetConnectionMetrics(logger *log.Logger, HOSTNAME string, dbConn *sql.DB) []Metric {
	var metrics = make([]Metric, 0)
	logger.Println("get connection metrics")

	var rows *sql.Rows
	var err error
	var total = int64(0)
	rows, err = dbConn.Query("select numbackends, datname from pg_stat_database")
	if err != nil {
		logger.Println("error: " + err.Error())
		return metrics
	}
	defer rows.Close()

	for rows.Next() {
		metric := Metric{}
		metric.Hostname = HOSTNAME
		metric.MetricName = "connections"
		metric.Units = "count"

		if err = rows.Scan(
			&metric.Value,
			&metric.DatabaseName); err != nil {
			logger.Println("error:" + err.Error())
			return metrics
		}

		total = total + metric.Value
		metrics = append(metrics, metric)
	}
	if err = rows.Err(); err != nil {
		logger.Println("error:" + err.Error())
		return metrics
	}

	//enter a metric for the whole cluster
	metric := Metric{}
	metric.Hostname = HOSTNAME
	metric.MetricName = "connections"
	metric.Units = "count"
	metric.Value = total
	metric.DatabaseName = "cluster"
	metrics = append(metrics, metric)

	return metrics

}
