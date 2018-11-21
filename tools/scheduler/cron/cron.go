package cron

import (
	"encoding/json"
	"errors"
	"fmt"
	"time"

	log "github.com/sirupsen/logrus"

	"github.com/crunchydata/crunchy-containers/tools/kubeapi"
	cv2 "gopkg.in/robfig/cron.v2"
)

func New(label, namespace string, client *kubeapi.KubeAPI) *Cron {
	cronClient := cv2.New()
	var p phony
	cronClient.AddJob("* * * * *", p)
	return &Cron{
		namespace:  namespace,
		label:      label,
		CronClient: cronClient,
		kubeClient: client,
		entries:    make(map[string]cv2.EntryID),
		scheduleTypes: []string{
			"pgbackrest",
			"pgbasebackup",
		},
	}
}

func (c *Cron) AddJobs() error {
	configs, err := c.kubeClient.GetConfigMaps(c.namespace, c.label, "")
	if err != nil {
		return err
	}

	for _, config := range configs {
		if _, ok := c.entries[string(config.Name)]; ok {
			continue
		}

		contextErr := log.WithFields(log.Fields{
			"configMap": config.Name,
			"filename":  config.Filename,
		})

		var schedule ScheduleTemplate
		if err := json.Unmarshal(config.Data, &schedule); err != nil {
			contextErr.WithFields(log.Fields{
				"error": err,
			}).Error("Failed unmarshaling configMap")
			continue
		}

		if err := c.validateSchedule(schedule); err != nil {
			contextErr.WithFields(log.Fields{
				"error": err,
			}).Error("Failed to validate configMap")
			continue
		}

		id, err := c.schedule(schedule)
		if err != nil {
			contextErr.WithFields(log.Fields{
				"error": err,
			}).Error("Failed to schedule configMap")
			continue
		}

		log.WithFields(log.Fields{
			"configMap":  string(config.Name),
			"type":       schedule.Type,
			"schedule":   schedule.Schedule,
			"namespace":  schedule.Namespace,
			"deployment": schedule.Deployment,
			"label":      schedule.Label,
			"container":  schedule.Container,
		}).Info("Added new schedule")
		c.entries[string(config.Name)] = id
	}
	return nil
}

func (c *Cron) DeleteJobs() error {
	configs, err := c.kubeClient.GetConfigMaps(c.namespace, c.label, "")
	if err != nil {
		return err
	}

	for name := range c.entries {
		found := false
		for _, config := range configs {
			if name == string(config.Name) {
				found = true
			}
		}
		if !found {
			log.WithFields(log.Fields{
				"scheduleName": name,
			}).Info("Removed schedule")
			c.CronClient.Remove(c.entries[name])
			delete(c.entries, name)
		}
	}
	return nil
}

func (c *Cron) validateSchedule(s ScheduleTemplate) error {
	_, err := cv2.Parse(s.Schedule)
	if err != nil {
		return err
	}

	validType := false
	for _, v := range c.scheduleTypes {
		if v == s.Type {
			validType = true
		}
	}

	if !validType {
		return fmt.Errorf("%s is not a valid schedulable type", s.Type)
	}

	if s.Type == "pgbackrest" {
		if s.PGBackRest.Deployment == "" && s.PGBackRest.Label == "" {
			return errors.New("Deployment or Label required for pgBackRest schedules")
		}
	}
	return nil
}

func (c *Cron) schedule(s ScheduleTemplate) (cv2.EntryID, error) {
	var job cv2.Job

	switch s.Type {
	case "pgbackrest":
		job = s.NewBackRestSchedule("db", c.kubeClient)
	case "pgbasebackup":
		job = s.NewBackBaseBackupSchedule(c.kubeClient)
	default:
		var id cv2.EntryID
		return id, fmt.Errorf("schedule type not implemented yet")
	}

	return c.CronClient.AddJob(s.Schedule, job)
}

type phony string

func (p phony) Run() {
	// This is a phony job that register with the cron service
	// that does nothing to prevent a bug that runs newly scheduled
	// jobs multiple times.
	_ = time.Now()
}
