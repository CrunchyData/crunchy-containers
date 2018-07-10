package runner

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
