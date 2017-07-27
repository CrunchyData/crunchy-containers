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
)

type Metric struct {
	Hostname string
	Name     string
	Value    float64
	Labels   map[string]string
}

func NewMetric(hostname, name string, value float64) Metric {
	return Metric{
		Hostname: hostname,
		Name:     name,
		Value:    value,
		Labels:   make(map[string]string),
	}
}

func (m Metric) AddLabel(label, value string) {
	m.Labels[label] = value
}

func (m Metric) Print() {
	fmt.Print("metric: " + m.Name)
	fmt.Print(" hostname: " + m.Hostname)
	fmt.Printf(" value: %f", m.Value)

	for label, value := range m.Labels {
		fmt.Printf(" %s: %s", label, value)
	}

	fmt.Println()
}
