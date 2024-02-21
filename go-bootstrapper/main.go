package main

import (
	"gitlab.com/amihan/common/tooling/go-bootstrapper/cmd"

	log "github.com/sirupsen/logrus"
)

// VERSION is the release version go-bootstrapper
const VERSION = "0.0.1"

func main() {
	log.SetLevel(log.DebugLevel)
	cmd.Execute(VERSION)
}
