package runner

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
