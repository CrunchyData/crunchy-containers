package collectapi

import (
	"github.com/akhenakh/statgo"
)

func GetMemoryMetrics(hostname string, s *statgo.Stat) []Metric {
	metrics := make([]Metric, 0)
	memInfo := s.MemStats()

	metric := NewMemoryMetric(hostname, "mem_total", float64(memInfo.Total))
	metrics = append(metrics, metric)

	metric = NewMemoryMetric(hostname, "mem_free", float64(memInfo.Free))
	metrics = append(metrics, metric)

	metric = NewMemoryMetric(hostname, "mem_used", float64(memInfo.Used))
	metrics = append(metrics, metric)

	metric = NewMemoryMetric(hostname, "mem_cache", float64(memInfo.Cache))
	metrics = append(metrics, metric)

	metric = NewMemoryMetric(hostname, "mem_swap_total", float64(memInfo.SwapTotal))
	metrics = append(metrics, metric)

	metric = NewMemoryMetric(hostname, "mem_swap_used", float64(memInfo.SwapUsed))
	metrics = append(metrics, metric)

	metric = NewMemoryMetric(hostname, "mem_swap_free", float64(memInfo.SwapFree))
	metrics = append(metrics, metric)

	return metrics
}
