package collectapi

import (
	"github.com/prometheus/client_golang/prometheus"
	"log"
)

const PREFIX = "crunchy_"

func WritePrometheusMetrics(logger *log.Logger, PROM_GATEWAY string, HOST string, metrics []Metric) error {
	var err error
	logger.Printf("writing %d metrics\n", len(metrics))
	for _, metric := range metrics {
		metric.Print()

		opts := prometheus.GaugeOpts{
			Name: PREFIX + metric.Name(),
			Help: "no help available",
		}

		opts.ConstLabels = metric.Labels()

		newMetric := prometheus.NewGauge(opts)
		newMetric.Set(metric.Value())
		if err := prometheus.PushCollectors(
			metric.Name(), HOST,
			PROM_GATEWAY,
			newMetric,
		); err != nil {
			logger.Printf("Could not push %s completion time to Pushgateway: %s\n",
				metric.Name(), err.Error())
			return err
		}
	}
	return err
}
