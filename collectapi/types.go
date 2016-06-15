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
	"fmt"
)

type Metric struct {
	Hostname     string
	MetricName   string
	DatabaseName string
	TableName    string
	Value        int64
	Units        string //count, item, percent, megabytes, time
	LockType     string //only used for lock metrics
	LockMode     string //only used for lock metrics
	DeadTup      int64  //only used for DeadRows metrics
	RelTup       int64  //only used for DeadRows metrics
	TableSz      int64  //used for DeadRows, Wraparound metrics
	TotalSz      int64  //used for DeadRows, Wraparound metrics
	LastVacuum   string //used for DeadRows, Wraparound, stale_age metrics
	LastAnalyze  string //only used for DeadRows, stale_age metrics
	AvNeeded     string //only used for DeadRows metrics
	Age          string //only used for Wraparound metrics
	Kind         string //only used for Wraparound metrics

}

func (f Metric) Print() {
	fmt.Print("metric: " + f.MetricName)
	fmt.Print(" hostname: " + f.Hostname)
	fmt.Print(" database: " + f.DatabaseName)
	if f.TableName != "" {
		fmt.Print(" tablename: " + f.TableName)
	}
	if f.LockType != "" {
		fmt.Print(" locktype: " + f.LockType)
		fmt.Print(" lockmode: " + f.LockMode)
	}
	fmt.Printf(" value: %d", f.Value)
	if f.MetricName == "pct_dead" {
		fmt.Print(" n_dead_tup: %d ", f.DeadTup)
		fmt.Print(" reltuples: %d", f.RelTup)
		fmt.Print(" table_sz: %d", f.TableSz)
		fmt.Print(" total_sz: %d ", f.TotalSz)
		fmt.Print(" last_vacuum: " + f.LastVacuum)
		fmt.Print(" last_analyze: " + f.LastAnalyze)
		fmt.Print(" av_needed: " + f.AvNeeded)
	}
	if f.MetricName == "wraparound" {
		fmt.Print(" age: " + f.Age)
		fmt.Print(" table_sz: %d", f.TableSz)
		fmt.Print(" total_sz: %d ", f.TotalSz)
		fmt.Print(" last_vacuum: " + f.LastVacuum)
		fmt.Print(" kind: " + f.Kind)
	}
	if f.MetricName == "stale_age" {
		fmt.Print(" last_analyze: " + f.LastAnalyze)
		fmt.Print(" last_vacuum: " + f.LastVacuum)
	}
	fmt.Println(" units: " + f.Units)
}
