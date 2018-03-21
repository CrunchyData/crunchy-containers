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

package config

import (
	"github.com/spf13/viper"
)

type Config struct {
	Host        string `mapstructure:"host"`
	Port        string `mapstructure:"port"`
	Username    string `mapstructure:"username"`
	Password    string `mapstructure:"password"`
	Database    string `mapstructure:"database"`
	Interval    string `mapstructure:"interval"`
	MinInterval int    `mapstructure:"mininterval"`
	MaxInterval int    `mapstructure:"maxinterval"`
}

func init() {
	viper.SetConfigType("yaml")
	viper.SetConfigName("config")

	viper.AddConfigPath(".")

	viper.SetEnvPrefix("pgsim")

	viper.BindEnv("host")
	viper.BindEnv("port")
	viper.BindEnv("username")
	viper.BindEnv("password")
	viper.BindEnv("interval")
	viper.BindEnv("mininterval")
	viper.BindEnv("maxinterval")
}

func SetConfigFile(file string) {
	viper.SetConfigFile(file)
}

func ReadConfig() Config {
	var c Config

	viper.ReadInConfig()
	viper.Unmarshal(&c)

	return c
}
