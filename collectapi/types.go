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
	"fmt"
	"strconv"
)

type Metric interface {
	Hostname() string
	Name() string
	Value() float64
	Labels() map[string]string
	Print()
}

type baseMetric struct {
	hostname string
	name     string
	value    float64
}

func (bm baseMetric) Hostname() string {
	return bm.hostname
}

func (bm baseMetric) Name() string {
	return bm.name
}

func (bm baseMetric) Value() float64 {
	return bm.value
}

type PGMetric struct {
	baseMetric
	DatabaseName string
	TableName    string
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

func (p PGMetric) Labels() map[string]string {
	labels := make(map[string]string)

	labels["DatabaseName"] = p.DatabaseName
	labels["Units"] = p.Units
	if p.TableName != "" {
		labels["TableName"] = p.TableName
	}

	if p.LockType != "" {
		labels["LockType"] = p.LockType
		labels["LockMode"] = p.LockMode
	}
	if p.LastVacuum != "" {
		labels["LastVacuum"] = p.LastVacuum
		labels["LastAnalyze"] = p.LastAnalyze
		labels["AvNeeded"] = p.AvNeeded
	}
	if p.Age != "" {
		labels["Age"] = p.Age
		labels["Kind"] = p.Kind
	}
	if p.name == "wraparound" {
		labels["TableSz"] = strconv.FormatInt(p.TableSz, 10)
		labels["TotalSz"] = strconv.FormatInt(p.TotalSz, 10)
	}
	if p.name == "pct_dead" {
		labels["DeadTup"] = strconv.FormatInt(p.DeadTup, 10)
		labels["RelTup"] = strconv.FormatInt(p.RelTup, 10)
		labels["TableSz"] = strconv.FormatInt(p.TableSz, 10)
		labels["TotalSz"] = strconv.FormatInt(p.TotalSz, 10)
	}

	return labels
}

func NewPGMetric(hostname, name string, value float64) PGMetric {
	return PGMetric{
		baseMetric: baseMetric{
			hostname: hostname,
			name:     name,
			value:    value,
		},
	}
}

func (p PGMetric) Print() {
	fmt.Print("metric: " + p.name)
	fmt.Print(" hostname: " + p.hostname)
	fmt.Print(" database: " + p.DatabaseName)
	if p.TableName != "" {
		fmt.Print(" tablename: " + p.TableName)
	}
	if p.LockType != "" {
		fmt.Print(" locktype: " + p.LockType)
		fmt.Print(" lockmode: " + p.LockMode)
	}

	fmt.Printf(" value: %f", p.Value())

	if p.name == "pct_dead" {
		fmt.Print(" n_dead_tup: %d ", p.DeadTup)
		fmt.Print(" reltuples: %d", p.RelTup)
		fmt.Print(" table_sz: %d", p.TableSz)
		fmt.Print(" total_sz: %d ", p.TotalSz)
		fmt.Print(" last_vacuum: " + p.LastVacuum)
		fmt.Print(" last_analyze: " + p.LastAnalyze)
		fmt.Print(" av_needed: " + p.AvNeeded)
	}
	if p.name == "wraparound" {
		fmt.Print(" age: " + p.Age)
		fmt.Print(" table_sz: %d", p.TableSz)
		fmt.Print(" total_sz: %d ", p.TotalSz)
		fmt.Print(" last_vacuum: " + p.LastVacuum)
		fmt.Print(" kind: " + p.Kind)
	}
	if p.name == "stale_age" {
		fmt.Print(" last_analyze: " + p.LastAnalyze)
		fmt.Print(" last_vacuum: " + p.LastVacuum)
	}
	fmt.Println(" units: " + p.Units)
}

type CPUMetric struct {
	baseMetric
}

func NewCPUMetric(hostname, name string, value float64) CPUMetric {
	return CPUMetric{
		baseMetric: baseMetric{
			hostname: hostname,
			name:     name,
		},
	}
}

func (o CPUMetric) Labels() map[string]string {
	labels := make(map[string]string)

	return labels
}

func (o CPUMetric) Print() {

}

type MemoryMetric struct {
	baseMetric
}

func NewMemoryMetric(hostname, name string, value float64) MemoryMetric {
	return MemoryMetric{
		baseMetric: baseMetric{
			hostname: hostname,
			name:     name,
			value:    value,
		},
	}
}

func (m MemoryMetric) Labels() map[string]string {
	labels := make(map[string]string)
	return labels
}

func (m MemoryMetric) Print() {
	fmt.Printf("Memory: %s Value: %f\n", m.Name(), m.Value())
}

type NetworkIOMetric struct {
	baseMetric
	Interface string
}

func NewNetworkIOMetric(hostname, name string, value float64) NetworkIOMetric {
	return NetworkIOMetric{
		baseMetric: baseMetric{
			hostname: hostname,
			name:     name,
			value:    value,
		},
	}
}

func (n NetworkIOMetric) Labels() map[string]string {
	labels := make(map[string]string)

	labels["Interface"] = n.Interface

	return labels
}

func (n NetworkIOMetric) Print() {
}
