package collectapi

import (
	"github.com/akhenakh/statgo"
)

func GetMemoryMetrics(hostname string, s *statgo.Stat) []Metric {
	metrics := make([]Metric, 0)
	memInfo := s.MemStats()

	metric := NewMetric(hostname, "mem_total", float64(memInfo.Total))
	metric.AddLabel("Units", "bytes")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "mem_free", float64(memInfo.Free))
	metric.AddLabel("Units", "bytes")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "mem_used", float64(memInfo.Used))
	metric.AddLabel("Units", "bytes")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "mem_cache", float64(memInfo.Cache))
	metric.AddLabel("Units", "bytes")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "mem_swap_total", float64(memInfo.SwapTotal))
	metric.AddLabel("Units", "bytes")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "mem_swap_used", float64(memInfo.SwapUsed))
	metric.AddLabel("Units", "bytes")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "mem_swap_free", float64(memInfo.SwapFree))
	metric.AddLabel("Units", "bytes")
	metrics = append(metrics, metric)

	return metrics
}
