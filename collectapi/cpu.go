package collectapi

import (
	"github.com/akhenakh/statgo"
)

func GetCPUMetrics(hostname string, s *statgo.Stat) []Metric {
	metrics := make([]Metric, 0)
	cpuInfo := s.CPUStats()

	metric := NewCPUMetric(hostname, "cpu_user", cpuInfo.User)
	metrics = append(metrics, metric)

	metric = NewCPUMetric(hostname, "cpu_kernel", cpuInfo.Kernel)
	metrics = append(metrics, metric)

	metric = NewCPUMetric(hostname, "cpu_idle", cpuInfo.Idle)
	metrics = append(metrics, metric)

	metric = NewCPUMetric(hostname, "cpu_iowait", cpuInfo.IOWait)
	metrics = append(metrics, metric)

	metric = NewCPUMetric(hostname, "cpu_swap", cpuInfo.Swap)
	metrics = append(metrics, metric)

	metric = NewCPUMetric(hostname, "cpu_nice", cpuInfo.Nice)
	metrics = append(metrics, metric)

	metric = NewCPUMetric(hostname, "cpu_load_min_1", cpuInfo.LoadMin1)
	metrics = append(metrics, metric)

	metric = NewCPUMetric(hostname, "cpu_load_min_5", cpuInfo.LoadMin5)
	metrics = append(metrics, metric)

	metric = NewCPUMetric(hostname, "cpu_load_min_15", cpuInfo.LoadMin15)
	metrics = append(metrics, metric)

	return metrics
}
