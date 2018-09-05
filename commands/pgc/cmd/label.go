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
	"fmt"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"strings"
	"k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"github.com/crunchydata/crunchy-containers/commands/kubeapi"

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
  pgc label [--overwrite] TYPE NAME KEY=VALUE

  TYPE - resource type, currently only 'pod' is supported
  NAME - the name of the resource to apply the label against
  KEY - the name of the label to be applied
  VALUE- the value to be associated with the label KEY

Example:

  pgc label --overwrite pod postres-primary environment=prod 

.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Debug("label called")

		if len(args) == 0  {
			log.Error("A resource type and name must be specified.")
			return
		}

		resources, labels := parseAndClassifyArgs(args)
		labelResource(resources, labels)
	},
}

func init() {

	labelCmd.Flags().BoolVarP(&Overwrite, "overwrite", "o", false, "--overwrite forces an existing label to be overwritten")
	RootCmd.AddCommand(labelCmd)

}

func labelResource(resources map[string]string, labels map[string]string) {

	if DebugFlag {
		dumpParsedArgs(resources, labels)
	}

	// oocFlag := RootCmd.PersistentFlags().Lookup("remote").Value

	clientset, namespace, _ := kubeapi.GetClientConfig(OOCFlag, Namespace)

	for _, podName := range resources {

		podClient := clientset.CoreV1().Pods(namespace)

		thePod, podErr := podClient.Get(podName, metav1.GetOptions{})

		if podErr != nil {
			log.WithFields(log.Fields {
				"pod": podName,
				"namespace" : namespace,
				}).Error("Pod not found in namespace.")
			continue
		}


		podLabels := thePod.GetLabels() // get current labels assigned to pod

		newLabels := map[string]string{}

		// Leverage last in wins, for overwrite during merge.
		if Overwrite {
			mergeMaps(podLabels, newLabels)
			mergeMaps(labels, newLabels)
		} else {
			mergeMaps(labels, newLabels)
			mergeMaps(podLabels, newLabels)
		}


		if DebugFlag {
			fmt.Println("New Labels: ")
			for k,v := range newLabels {
				fmt.Printf("	%s:%s\n", k, v)
			}
		}

		thePod.SetLabels(newLabels)

		podClient.Update(thePod)

	}

}

// given two maps, assign all key value pairs found in source to dest
// identical keys will get overwritten
func mergeMaps(source map[string]string, dest map[string]string) {

	for k,v := range source {
		dest[k] = v
	}
}

func parseAndClassifyArgs(args []string)(resources map[string]string, labels map[string]string ) {


	labels = map[string]string{}
	resources = map[string]string{}
	resType := ""	// placeholder for resource type 
	
	for _, item := range args {
	
		// there is an assumption here that labels appear with = and resources
		// separated by a space in pairs. Minimal works for now.
		if strings.Contains(item, "=") {
			// processing a label
			splitLabel := strings.Split(item, "=")
			labels[splitLabel[0]] = splitLabel[1]

		} else {
			// processing part of a resource pair
			if len(resType) > 0 {
				resources[resType] = item
				resType = ""
				
			} else {
				resType = item
			}

		}
	}



	return resources, labels
}



func dumpParsedArgs(resources map[string]string, labels map[string]string) {

	
	fmt.Printf("Resources: \n")
	for k, v := range resources { 
		fmt.Printf("	%s:%s\n", k, v)
	}

	fmt.Printf("Labels: \n")
	for k, v := range labels { 
		fmt.Printf("	%s:%s\n", k, v)
	}

fmt.Println("Overwrite: ", Overwrite)
fmt.Println("")

}

func dumpPodInfo(pods []v1.Pod ) {

	for _, pod := range pods {

		podLabels := pod.GetLabels()
		fmt.Printf("Pod: %s\n", pod.ObjectMeta.Name) 
		fmt.Printf("Labels: \n")
		for k,v := range podLabels {
			fmt.Printf("	%s:%s\n", k, v)
		}
		fmt.Printf("\n")

	}
	
}
