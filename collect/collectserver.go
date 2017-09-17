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

package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus/push"
	dto "github.com/prometheus/client_model/go"
	"github.com/prometheus/common/expfmt"
)

type flagStringArray []string

func (f *flagStringArray) String() string {
	return ""
}

func (f *flagStringArray) Set(value string) error {
	*f = append(*f, value)
	return nil
}

var (
	exporterUrls flagStringArray

	gateway = flag.String(
		"gateway", "",
		"Prometheus pushgateway address",
	)

	interval = flag.Int(
		"interval", 3,
		"Polling interval (minutes)",
	)
)

func init() {
	flag.Var(
		&exporterUrls,
		"exporter",
		"List of exporter addresses (comma separated)",
	)
}

type MetricGatherer struct {
	url string
}

func NewMetricGatherer(url string) *MetricGatherer {
	return &MetricGatherer{
		url: url,
	}
}

func (m *MetricGatherer) Gather() ([]*dto.MetricFamily, error) {
	tmp := new(dto.MetricFamily)
	metrics := make([]*dto.MetricFamily, 0)

	res, err := http.Get(m.url)

	if err != nil {
		fmt.Println(err.Error())
		return metrics, err
	}

	format := expfmt.Negotiate(res.Header)
	decoder := expfmt.NewDecoder(res.Body, format)

	for decoder.Decode(tmp) != io.EOF {
		metric := new(dto.MetricFamily)
		*metric = *tmp
		metrics = append(metrics, metric)
	}

	return metrics, nil
}

func main() {
	flag.Parse()

	if len(*gateway) == 0 {
		fmt.Println("A push gateway was not specified.")
		fmt.Println("A gateway URL can be provided using the -gateway option.")
		os.Exit(1)
	}

	duration := time.Duration(*interval) * time.Minute

	gatherers := make([]*MetricGatherer, 0)

	for _, url := range exporterUrls {
		gatherers = append(gatherers, NewMetricGatherer(url))
	}

	for {
		for _, g := range gatherers {
			if err := push.AddFromGatherer("crunchy-collect", nil,
				*gateway, g,
			); err != nil {
				fmt.Println(err.Error())
			}
		}
		time.Sleep(duration)
	}
}
