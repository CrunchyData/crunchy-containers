package main

import (
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/crunchydata/crunchy-containers/tools/kubeapi"
	"github.com/crunchydata/crunchy-containers/tools/scheduler/cron"
	log "github.com/sirupsen/logrus"
)

const (
	schedulerLabel = "crunchy-scheduler=true"
	namespaceEnv   = "NAMESPACE"
	timeout        = time.Second * 30
	inCluster      = true
)

var namespace string

func init() {
	log.SetLevel(log.InfoLevel)
	log.SetFormatter(&log.TextFormatter{
		FullTimestamp:   true,
		TimestampFormat: "2006-01-02 15:04:05",
	})

	namespace = os.Getenv(namespaceEnv)
	if namespace == "" {
		log.WithFields(log.Fields{}).Fatalf("Failed to get namespace environment: %s", namespaceEnv)
	}
}

func main() {
	log.Info("Starting Crunchy Scheduler")
	kubeClient, err := kubeapi.New(timeout, inCluster)
	if err != nil {
		log.WithFields(log.Fields{
			"error": err,
		}).Fatal("Could not create a new instance of kubeclient")
	}

	cron := cron.New(schedulerLabel, namespace, kubeClient)
	cron.CronClient.Start()

	sigs := make(chan os.Signal, 1)
	done := make(chan bool, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		sig := <-sigs
		log.WithFields(log.Fields{
			"signal": sig,
		}).Warning("Received signal")
		done <- true
	}()

	go func() {
		for {
			if err := cron.AddJobs(); err != nil {
				log.WithFields(log.Fields{
					"error": err,
				}).Error("Failed to add cron entries")
			}
			time.Sleep(time.Second * 10)
		}
	}()

	go func() {
		for {
			time.Sleep(time.Second * 10)
			if err := cron.DeleteJobs(); err != nil {
				log.WithFields(log.Fields{
					"error": err,
				}).Error("Failed to delete cron entries")
			}
		}
	}()

	for {
		select {
		case <-done:
			log.Warning("Shutting down scheduler")
			cron.CronClient.Stop()
			os.Exit(0)
		default:
			time.Sleep(time.Second * 1)
		}
	}
}
