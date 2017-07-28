package collectapi

import (
	"github.com/akhenakh/statgo"
)

func GetNetworkIOMetrics(hostname string, s *statgo.Stat) []Metric {
	metrics := make([]Metric, 0)

	for _, net := range s.NetIOStats() {
		metric := NewMetric(hostname, "net_tx", float64(net.TX))
		metric.AddLabel("Units", "bytes")
		metric.AddLabel("Interface", net.IntName)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "net_rx", float64(net.RX))
		metric.AddLabel("Units", "bytes")
		metric.AddLabel("Interface", net.IntName)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "net_ipackets", float64(net.IPackets))
		metric.AddLabel("Units", "count")
		metric.AddLabel("Interface", net.IntName)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "net_opackets", float64(net.OPackets))
		metric.AddLabel("Units", "count")
		metric.AddLabel("Interface", net.IntName)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "net_ierrors", float64(net.IErrors))
		metric.AddLabel("Units", "count")
		metric.AddLabel("Interface", net.IntName)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "net_oerrors", float64(net.OErrors))
		metric.AddLabel("Units", "count")
		metric.AddLabel("Interface", net.IntName)
		metrics = append(metrics, metric)

		metric = NewMetric(hostname, "net_collisions", float64(net.Collisions))
		metric.AddLabel("Units", "count")
		metric.AddLabel("Interface", net.IntName)
		metrics = append(metrics, metric)
	}

	return metrics
}
