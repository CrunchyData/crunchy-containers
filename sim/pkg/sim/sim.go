/*
 Copyright 2017 - 2018 Crunchy Data Solutions, Inc.
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

package sim

import (
	"database/sql"
	"fmt"
	"math/rand"
	"sync"
	"time"

	_ "github.com/lib/pq"

	"github.com/crunchydata/crunchy-containers/sim/pkg/config"
)

type PGSim struct {
	done    chan bool
	wait    *sync.WaitGroup
	timer   *time.Timer
	config  config.Config
	queries map[string]string
	db      *sql.DB
}

func NewPGSim(c config.Config, q map[string]string) *PGSim {
	return &PGSim{
		done:    make(chan bool),
		wait:    &sync.WaitGroup{},
		config:  c,
		queries: q,
	}
}

func (p *PGSim) connect() error {
	var err error

	connString := fmt.Sprintf("host=%s port=%s", p.config.Host, p.config.Port)
	connString += fmt.Sprintf(" dbname=%s", p.config.Database)
	connString += fmt.Sprintf(" user=%s ", p.config.Username)
	connString += fmt.Sprintf(" password=%s", p.config.Password)
	connString += fmt.Sprintf(" sslmode=disable")

	fmt.Println(connString)

	p.db, err = sql.Open("postgres", connString)

	return err
}

func (p *PGSim) Start() {
	// Join the simulation wait group.
	p.wait.Add(1)
	defer p.wait.Done()

	err := p.connect()

	if err != nil {
		fmt.Println(err.Error())
		return
	}

	// Initialize the timer.
	var intervalUnit time.Duration
	switch p.config.Interval {
	case "millisecond":
		intervalUnit = time.Millisecond
	case "second":
		intervalUnit = time.Second
	case "minute":
		intervalUnit = time.Minute
	default:
		intervalUnit = time.Second
	}

	min := p.config.MinInterval
	max := p.config.MaxInterval
	duration := intervalUnit * time.Duration(rand.Intn(max-min)+min)

	timer := time.NewTimer(duration)
	numQueries := len(p.queries)
	queryKeys := make([]string, 0)

	for k := range p.queries {
		queryKeys = append(queryKeys, k)
	}

	for {
		// Check if the if the simulation should stop.
		select {
		case <-p.done:
			fmt.Println("Stopping simulation...")
			return
		default:
		}

		// Wait for the timer to expire.
		<-timer.C

		// Choose next query.
		index := rand.Intn(numQueries)
		key := queryKeys[index]
		query := p.queries[key]

		// Excecute simulation query.
		go p.Execute(query)
		// go p.Execute(query)

		// Reset the timer to a new random duration
		duration = intervalUnit * time.Duration(rand.Intn(max-min)+min)
		timer.Reset(duration)
	}
}

func (p *PGSim) Stop() {
	close(p.done)

	// Wait for all jobs to complete.
	p.wait.Wait()
}

func (p *PGSim) Execute(query string) {
	// Join simulation wait group.
	p.wait.Add(1)
	defer p.wait.Done()

	rows, err := p.db.Query(query)
	defer rows.Close()

	if err != nil {
		fmt.Println(err)
	}
}
