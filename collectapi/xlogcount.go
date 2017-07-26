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
	"bytes"
	"database/sql"
	_ "github.com/lib/pq"
	"log"
	"os/exec"
	"strconv"
	"strings"
)

func XlogCountMetrics(logger *log.Logger, HOSTNAME string, dbConn *sql.DB) []Metric {
	logger.Println("XlogCountMetrics 1.1.0")

	var metrics = make([]Metric, 0)

	var count float64

	var cmd *exec.Cmd
	cmd = exec.Command("/opt/cpm/bin/xlog-count.sh")
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		logger.Println("error:" + err.Error())
		return metrics
	}
	result := strings.TrimSpace(out.String())
	logger.Println("xlog count got back " + result)
	count, err = strconv.ParseFloat(result, 64)

	metric := NewPGMetric(HOSTNAME, "xlog_count")
	metric.Units = "count"
	metric.SetValue(count)
	metric.DatabaseName = "cluster"
	metrics = append(metrics, metric)

	return metrics

}
