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

package cli

import (
	"bytes"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"

	"github.com/spf13/cobra"
	"gopkg.in/yaml.v2"

	"github.com/crunchydata/crunchy-containers/sim/pkg/config"
	"github.com/crunchydata/crunchy-containers/sim/pkg/sim"
)

var (
	configFile string
)

var simCmd = &cobra.Command{
	Use:   "crunchy-sim <query_file>",
	Short: "",
	RunE:  runMainCmd,
}

func init() {
	flags := simCmd.Flags()

	flags.StringVarP(&configFile, "config", "", "", "path to config file")

	simCmd.Args = cobra.ExactArgs(1)
}

func runMainCmd(cmd *cobra.Command, args []string) error {

	if configFile != "" {
		config.SetConfigFile(configFile)
	}

	c := config.ReadConfig()

	fmt.Println(c)

	// Read query file
	q := new(map[string]string)
	path, err := filepath.Abs(args[0])

	if err != nil {
		return err
	}

	f, err := os.Open(path)

	if err != nil {
		return err
	}

	buf := new(bytes.Buffer)
	buf.ReadFrom(f)

	if err := yaml.Unmarshal(buf.Bytes(), &q); err != nil {
		fmt.Println(err.Error())
	}

	// Initialize simulation
	s := sim.NewPGSim(c, *q)

	// Start simulation
	go s.Start()

	// Wait for SIGINT to cancel simulation
	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGTERM)
	<-ch

	s.Stop()

	return nil
}
