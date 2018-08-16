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
	// "bytes"
	// "encoding/json"
	"fmt"
	log "github.com/Sirupsen/logrus"
	// msgs "github.com/crunchydata/postgres-operator/apiservermsgs"
	"github.com/spf13/cobra"
	// "net/http"
	// "os"
)

var LabelCmdLabel string
var LabelMap map[string]string
var DeleteLabel bool

var labelCmd = &cobra.Command{
	Use:   "label",
	Short: "Label a set of clusters",
	Long: `Update label on one or more resources

A valid label value consists of letters and/or numbers with a max length of  63 characters. If --overwrite is specified,
existing labels can be overwritten, otherwise attempting to overwrite an existing label will result in an error.

Usage:
  pgc label [--overwrite] TYPE NAME KEY_1=VAL_1 ... KEY_N=VAL_N

Example:

  pgc label --overwrite pod postres-primary environment=prod 

.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Debug("label called")
		var inValid bool = false

		if len(args) == 0  {
			log.Error("A resource type and name must be specified.")
			inValid = true
		}

		// if Pod == "" {
		// 	fmt.Println("No pod specified")
		// 	inValid = true
		// }

		if LabelCmdLabel == "" {
			log.Error(`You must specify the label to apply.`)
			inValid = true
		} 

		if (inValid) {
			return
		}
		labelResource(args)
	},
}

func init() {

	labelCmd.Flags().BoolVarP(&Overwrite, "overwrite", "o", false, "--overwrite forces an existing label to be overwritten")
	labelCmd.Flags().StringVarP(&Pod, "pods", "", "", "Specify the name of the pod to apply label to")
	labelCmd.MarkFlagRequired("pods")
	labelCmd.Flags().StringVarP(&LabelCmdLabel, "label", "l", "", "The new label to apply for specified resource")
	labelCmd.MarkFlagRequired("label")

	RootCmd.AddCommand(labelCmd)

}

func labelResource(args []string) {
	// var err error



fmt.Println("Args: ", args)
fmt.Println("Pod: ", Pod)
fmt.Println("Label: ", LabelCmdLabel)

}