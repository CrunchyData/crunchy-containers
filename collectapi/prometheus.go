package collectapi

import (
	"github.com/prometheus/client_golang/prometheus"
	"log"
	"strconv"
)

const PREFIX = "crunchy_"

func WritePrometheusMetrics(logger *log.Logger, PROM_GATEWAY string, HOST string, metrics []Metric) error {
	var err error
	logger.Printf("writing %d metrics\n", len(metrics))
	for i := 0; i < len(metrics); i++ {
		//metrics[i].Print()

		opts := prometheus.GaugeOpts{
			Name: PREFIX + metrics[i].MetricName,
			Help: "no help available",
		}

		labels := make(map[string]string)

		labels["DatabaseName"] = metrics[i].DatabaseName
		labels["Units"] = metrics[i].Units
		if metrics[i].TableName != "" {
			labels["TableName"] = metrics[i].TableName
		}

		if metrics[i].LockType != "" {
			labels["LockType"] = metrics[i].LockType
			labels["LockMode"] = metrics[i].LockMode
		}
		if metrics[i].LastVacuum != "" {
			labels["LastVacuum"] = metrics[i].LastVacuum
			labels["LastAnalyze"] = metrics[i].LastAnalyze
			labels["AvNeeded"] = metrics[i].AvNeeded
		}
		if metrics[i].Age != "" {
			labels["Age"] = metrics[i].Age
			labels["Kind"] = metrics[i].Kind
		}
		if metrics[i].MetricName == "wraparound" {
			labels["TableSz"] = strconv.FormatInt(metrics[i].TableSz, 10)
			labels["TotalSz"] = strconv.FormatInt(metrics[i].TotalSz, 10)
		}
		if metrics[i].MetricName == "pct_dead" {
			labels["DeadTup"] = strconv.FormatInt(metrics[i].DeadTup, 10)
			labels["RelTup"] = strconv.FormatInt(metrics[i].RelTup, 10)
			labels["TableSz"] = strconv.FormatInt(metrics[i].TableSz, 10)
			labels["TotalSz"] = strconv.FormatInt(metrics[i].TotalSz, 10)
		}

		opts.ConstLabels = labels

		newMetric := prometheus.NewGauge(opts)
		newMetric.Set(float64(metrics[i].Value))
		if err := prometheus.PushCollectors(
			metrics[i].MetricName, HOST,
			PROM_GATEWAY,
			newMetric,
		); err != nil {
			logger.Println("Could not push " + metrics[i].MetricName + "completion time to Pushgateway:" + err.Error())
			return err
		}
	}
	return err
}
