package main

import (
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/crunchydata/crunchy-containers/tools/kubeapi"
	"github.com/crunchydata/crunchy-containers/tools/scheduler/cron"
	log "github.com/sirupsen/logrus"
)

const (
	schedulerLabel = "crunchy-scheduler=true"
	namespaceEnv   = "NAMESPACE"
	timeoutEnv     = "TIMEOUT"
	inCluster      = true
)

var namespace string
var timeout time.Duration
var seconds int

func init() {
	var err error
	log.SetLevel(log.InfoLevel)
	log.SetFormatter(&log.TextFormatter{
		FullTimestamp:   true,
		TimestampFormat: "2006-01-02 15:04:05",
	})

	namespace = os.Getenv(namespaceEnv)
	if namespace == "" {
		log.WithFields(log.Fields{}).Fatalf("Failed to get namespace environment: %s", namespaceEnv)
	}

	seconds = 300
	secondsStr := os.Getenv(timeoutEnv)
	if secondsStr == "" {
		log.WithFields(log.Fields{}).Info("No timeout set, defaulting to 300 seconds")
	} else {
		seconds, err = strconv.Atoi(secondsStr)
		if err != nil {
			log.WithFields(log.Fields{}).Fatalf("Failed to convert timeout env to seconds: %s", err)
		}
	}

	log.WithFields(log.Fields{}).Infof("Setting timeout to: %d", seconds)
	timeout = time.Second * time.Duration(seconds)
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
