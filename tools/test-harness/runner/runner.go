package runner

/*
Copyright 2018 - 2021 Crunchy Data Solutions, Inc.
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
	"os"
	"os/exec"
)

// Run method executes a given command and can optionally
// set environment variables if required.
func Run(dir string, envs []string) (string, error) {
	var out []byte
	cmd := exec.Command(dir)
	cmd.Env = os.Environ()
	for _, env := range envs {
		cmd.Env = append(cmd.Env, os.ExpandEnv(env))
	}
	out, err := cmd.CombinedOutput()
	return string(out), err
}

// GetEnv method tests if an environment variable is set.
func GetEnv(name []string) error {
	for _, v := range name {
		env := os.Getenv(v)
		if env == "" {
			return fmt.Errorf("environment variable does not exist: %s", v)
		}
	}
	return nil
}
