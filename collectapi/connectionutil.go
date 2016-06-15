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

func GetConnectionUtilMetrics(logger *log.Logger, HOSTNAME string, dbConn *sql.DB) *Metric {
	logger.Println("get connection util metrics")
	metric := new(Metric)

	var bootval int64
	var usedval int64
	err := dbConn.QueryRow("select boot_val::numeric , (select sum(numbackends) from pg_stat_database) as used_val from pg_settings where name = 'max_connections'").Scan(&bootval, &usedval)
	if err != nil {
		logger.Println("error: " + err.Error())
		return metric
	}

	metric.Hostname = HOSTNAME
	metric.MetricName = "connectionutil"
	metric.Units = "percent"
	metric.Value = int64(float64(usedval) / float64(bootval) * 100.0)
	metric.DatabaseName = "cluster"

	return metric

}
