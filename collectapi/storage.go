package collectapi

import (
	"github.com/akhenakh/statgo"
)

func GetStorageMetrics(hostname string, s *statgo.Stat) []Metric {
	metrics := make([]Metric, 0)

	for _, storage := range s.FSInfos() {
		if storage.MountPoint != "/pgdata" {
			continue
		}

		metric := NewMetric(hostname, "storage_size", float64(storage.Size))
		metric.AddLabel("Units", "bytes")
		metric.AddLabel("DeviceName", storage.DeviceName)
		metric.AddLabel("FSType", storage.FSType)
		metric.AddLabel("MountPoint", storage.MountPoint)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "storage_used", float64(storage.Used))
		metric.AddLabel("Units", "bytes")
		metric.AddLabel("DeviceName", storage.DeviceName)
		metric.AddLabel("FSType", storage.FSType)
		metric.AddLabel("MountPoint", storage.MountPoint)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "storage_free", float64(storage.Free))
		metric.AddLabel("Units", "bytes")
		metric.AddLabel("DeviceName", storage.DeviceName)
		metric.AddLabel("FSType", storage.FSType)
		metric.AddLabel("MountPoint", storage.MountPoint)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "storage_available", float64(storage.Available))
		metric.AddLabel("Units", "bytes")
		metric.AddLabel("DeviceName", storage.DeviceName)
		metric.AddLabel("FSType", storage.FSType)
		metric.AddLabel("MountPoint", storage.MountPoint)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "storage_inodes_total", float64(storage.TotalInodes))
		metric.AddLabel("Units", "count")
		metric.AddLabel("DeviceName", storage.DeviceName)
		metric.AddLabel("FSType", storage.FSType)
		metric.AddLabel("MountPoint", storage.MountPoint)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "storage_indoes_used", float64(storage.UsedInodes))
		metric.AddLabel("Units", "count")
		metric.AddLabel("DeviceName", storage.DeviceName)
		metric.AddLabel("FSType", storage.FSType)
		metric.AddLabel("MountPoint", storage.MountPoint)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "storage_inodes_free", float64(storage.FreeInodes))
		metric.AddLabel("Units", "count")
		metric.AddLabel("DeviceName", storage.DeviceName)
		metric.AddLabel("FSType", storage.FSType)
		metric.AddLabel("MountPoint", storage.MountPoint)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "storage_inodes_available", float64(storage.AvailableInodes))
		metric.AddLabel("Units", "count")
		metric.AddLabel("DeviceName", storage.DeviceName)
		metric.AddLabel("FSType", storage.FSType)
		metric.AddLabel("MountPoint", storage.MountPoint)
		metrics = append(metrics, metric)
	}

	return metrics
}
