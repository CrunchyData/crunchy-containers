package kubeapi

import (
"flag"
"path/filepath"
"os"
"strings"
"bufio"

"k8s.io/client-go/kubernetes"
"k8s.io/client-go/tools/clientcmd"
"k8s.io/client-go/rest"
)

func GetClientConfig ()(* kubernetes.Clientset,  string, error) {

	var kubeconfig *string
	var config *rest.Config 
	var err error



	if inAContainer() {
		config, err = rest.InClusterConfig()
	} else if home := homeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "")
		// use the current context in kubeconfig
		config, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)

		if err != nil {
				panic(err.Error())
		}

	} else {
		// kubeconfig = flag.String("kubeconfig", "", "/etc/origin/master/admin.kubeconfig")
		//	config, err = rest.InClusterConfig()
		panic("Unable to obtain a cluster configuration. Exiting.")
	}
	flag.Parse()


	// create the clientset
	clientset, err := kubernetes.NewForConfig(config)

	if err != nil {
		panic(err.Error())
	}

	namespace := getNamespace()


	return clientset, namespace, err
}

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	return os.Getenv("USERPROFILE") // windows
}

func inAContainer() bool {

	// based on this post for how to determine if running inside a container.
	// https://stackoverflow.com/questions/20010199/how-to-determine-if-a-process-runs-inside-lxc-docker

	var cgroupFile = "/proc/1/cgroup"

	inFile, _ := os.Open(cgroupFile)
	defer inFile.Close()

	// read first line, determine cgroup structure
	scanner := bufio.NewScanner(inFile)
	scanner.Split(bufio.ScanLines) 
	scanner.Scan()
	pieces := strings.Split(scanner.Text(), ":")

	// if the 3rd piece is more than a single "/", we are in a container
	if len(pieces[2]) > 1 {
		return true
	}

	return false
}




func getNamespace() string {

	if ns := os.Getenv("CCP_NAMESPACE"); ns != "" {
		return ns
	}
	return "default"


}

