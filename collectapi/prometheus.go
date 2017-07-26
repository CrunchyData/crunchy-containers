package collectapi

import (
	"github.com/prometheus/client_golang/prometheus"
	"log"
)

const PREFIX = "crunchy_"

func WritePrometheusMetrics(logger *log.Logger, PROM_GATEWAY string, HOST string, metrics []Metric) error {
	var err error
	logger.Printf("writing %d metrics\n", len(metrics))
	for i := 0; i < len(metrics); i++ {
		//metrics[i].Print()

		opts := prometheus.GaugeOpts{
			Name: PREFIX + metrics[i].Name(),
			Help: "no help available",
		}

		opts.ConstLabels = metrics[i].Labels()

		newMetric := prometheus.NewGauge(opts)
		newMetric.Set(float64(metrics[i].Value()))
		if err := prometheus.PushCollectors(
			metrics[i].Name(), HOST,
			PROM_GATEWAY,
			newMetric,
		); err != nil {
			logger.Printf("Could not push %s completion time to Pushgateway: %s\n", metrics[i].Name(), err.Error())
			return err
		}
	}
	return err
}
