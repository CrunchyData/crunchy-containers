package cmd

/*
 Copyright 2017-2018 Crunchy Data Solutions, Inc.
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

import (
	log "github.com/Sirupsen/logrus"
	"github.com/fatih/color"
	"github.com/spf13/cobra"
	"os"
)

// RED ...
var RED func(a ...interface{}) string

// GREEN ...
var GREEN func(a ...interface{}) string

var OutputFormat string
var APIServerURL string
var Labelselector string
var DebugFlag bool
var Pod string
var Overwrite bool
var Debug bool

// RootCmd represents the base command when called without any subcommands
var RootCmd = &cobra.Command{
	Use:   "pgc",
	Short: "The Crunchy Postgres Container Client",
	Long: "The pgc command allows you to modify resources in an Kubenetes Cluster, including Openshift",
	// Uncomment the following line if your bare application
	// has an action associated with it:
	//	Run: func(cmd *cobra.Command, args []string) { },
}

// Execute adds all child commands to the root command sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {

	if err := RootCmd.Execute(); err != nil {
		log.Debug(err.Error())
		os.Exit(-1)
	}

}

func init() {

	cobra.OnInitialize(initConfig)
	log.Debug("init called")
	GREEN = color.New(color.FgGreen).SprintFunc()
	RED = color.New(color.FgRed).SprintFunc()

	RootCmd.PersistentFlags().BoolVarP(&DebugFlag, "debug", "d", false, "enable debug with true")

}

func initConfig() {
	if DebugFlag {
		log.SetLevel(log.DebugLevel)
		log.Debug("debug flag is set to true")
	}

	log.Debug("initConfig() called.")
}

func generateBashCompletion() {
	file, err2 := os.Create("/tmp/pgc-bash-completion.out")
	if err2 != nil {
		log.Error(err2.Error())
	}
	defer file.Close()
	RootCmd.GenBashCompletion(file)
}