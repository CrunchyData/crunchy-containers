package collectapi

import (
	"github.com/akhenakh/statgo"
)

func GetNetworkIOMetrics(hostname string, s *statgo.Stat) []Metric {
	metrics := make([]Metric, 0)

	for _, net := range s.NetIOStats() {
		metric := NewNetworkIOMetric(hostname, "net_tx", float64(net.TX))
		metric.Interface = net.IntName
		metrics = append(metrics, metric)

		metric = NewNetworkIOMetric(hostname, "net_rx", float64(net.RX))
		metric.Interface = net.IntName
		metrics = append(metrics, metric)

		metric = NewNetworkIOMetric(hostname, "net_ipackets", float64(net.IPackets))
		metric.Interface = net.IntName
		metrics = append(metrics, metric)

		metric = NewNetworkIOMetric(hostname, "net_opackets", float64(net.OPackets))
		metric.Interface = net.IntName
		metrics = append(metrics, metric)

		metric = NewNetworkIOMetric(hostname, "net_ierrors", float64(net.IErrors))
		metric.Interface = net.IntName
		metrics = append(metrics, metric)

		metric = NewNetworkIOMetric(hostname, "net_oerrors", float64(net.OErrors))
		metric.Interface = net.IntName
		metrics = append(metrics, metric)

		metric = NewNetworkIOMetric(hostname, "net_collisions", float64(net.Collisions))
		metric.Interface = net.IntName
		metrics = append(metrics, metric)
	}

	return metrics
}
