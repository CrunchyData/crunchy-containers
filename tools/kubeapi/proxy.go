package kubeapi

import (
	"bytes"
	"fmt"
	"io"
	"net"
	"net/http"
	"strconv"
	"time"

	"k8s.io/client-go/tools/portforward"
	"k8s.io/client-go/transport/spdy"
)

// Proxy is a data structure used when configuring a
// port forward proxy.
type Proxy struct {
	Hostname  string
	Local     int
	Remote    int
	Namespace string
	PodName   string
	Out       io.Writer
	stopChan  chan struct{}
	readyChan chan struct{}
	api       *KubeAPI
}

// NewProxy method creates a new port forwarding proxy.
func (k *KubeAPI) NewProxy(local, remote int, pod, namespace string) (*Proxy, error) {
	var stdout bytes.Buffer
	return &Proxy{
		Hostname:  "127.0.0.1",
		Local:     local,
		Remote:    remote,
		Namespace: namespace,
		PodName:   pod,
		Out:       &stdout,
		stopChan:  make(chan struct{}, 1),
		readyChan: make(chan struct{}, 1),
		api:       k,
	}, nil
}

// Close method cleans up a port forwarding proxy.
func (p *Proxy) Close() {
	close(p.stopChan)
}

// ForwardPort method forwards the configured ports
// configured in an instance of Proxy.
func (p *Proxy) ForwardPort() error {
	time.Sleep(5 * time.Second)
	url := p.api.Client.CoreV1().RESTClient().Post().
		Resource("pods").
		Namespace(p.Namespace).
		Name(p.PodName).
		SubResource("portforward").URL()

	tripper, upgrader, err := spdy.RoundTripperFor(p.api.Config)
	if err != nil {
		return err
	}

	dialer := spdy.NewDialer(upgrader, &http.Client{Transport: tripper}, "POST", url)

	local, err := p.getPort()
	if err != nil {
		return fmt.Errorf("no port available: %s", err)
	}
	p.Local = local

	ports := []string{fmt.Sprintf("%d:%d", p.Local, p.Remote)}

	pf, err := portforward.New(dialer, ports, p.stopChan, p.readyChan, p.Out, p.Out)
	if err != nil {
		return err
	}

	errChan := make(chan error)
	go func() {
		errChan <- pf.ForwardPorts()
	}()

	select {
	case err = <-errChan:
		return fmt.Errorf("forwarding ports: %v", err)
	case <-pf.Ready:
		return nil
	}
}

func (p *Proxy) getPort() (int, error) {
	l, err := net.Listen("tcp", fmt.Sprintf(":%d", p.Local))
	if err != nil {
		return 0, err
	}
	defer l.Close()

	_, portStr, err := net.SplitHostPort(l.Addr().String())
	if err != nil {
		return 0, err
	}
	port, err := strconv.Atoi(portStr)
	if err != nil {
		return 0, err
	}
	return port, err
}
