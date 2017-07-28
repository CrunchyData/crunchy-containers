package collectapi

import (
	"github.com/akhenakh/statgo"
)

func GetCPUMetrics(hostname string, s *statgo.Stat) []Metric {
	metrics := make([]Metric, 0)
	cpuInfo := s.CPUStats()

	metric := NewMetric(hostname, "cpu_user", cpuInfo.User)
	metric.AddLabel("Units", "percent")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "cpu_kernel", cpuInfo.Kernel)
	metric.AddLabel("Units", "percent")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "cpu_idle", cpuInfo.Idle)
	metric.AddLabel("Units", "percent")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "cpu_iowait", cpuInfo.IOWait)
	metric.AddLabel("Units", "percent")
	metrics = append(metrics, metric)

	metric = NewMetric(hostname, "cpu_nice", cpuInfo.Nice)
	metric.AddLabel("Units", "percent")
	metrics = append(metrics, metric)

	return metrics
}
