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
	"testing"
)

func TestCommandSuccess(t *testing.T) {
	out, err := Run("date", []string{})
	if err != nil {
		t.Fatalf("Could not run command: %s", err)
	}

	if len(out) <= 0 {
		t.Fatalf("Command output is empty, it shouldn't be.")
	}
}

func TestCommandFail(t *testing.T) {
	_, err := Run("foobar", []string{})
	if err == nil {
		t.Fatalf("Command 'foobar' should have failed, but didn't")
	}
}

func TestEnvSuccess(t *testing.T) {
	envs := []string{"PATH", "PWD"}
	err := GetEnv(envs)
	if err != nil {
		t.Fatalf("Environment variable should exist, it doesn't: %s", err)
	}
}

func TestEnvFail(t *testing.T) {
	envs := []string{"FOO", "BAR", "FOOBAR"}
	err := GetEnv(envs)
	if err == nil {
		t.Fatal("Environment variable shouldn't exist, it does.")
	}
}
