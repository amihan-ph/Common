package cmd

import (
	"os"

	"github.com/spf13/cobra"

	log "github.com/sirupsen/logrus"
)

var (
	root = &cobra.Command{
		Use:   "go-bootstraper",
		Short: "Golang project boiler plate code generator",
		Long:  `Go Bootstrapper is a tool for generating Amihan standard skeleton golang projects`,
	}
)

// Execute is the entrypoint into the application. Based on spf13/cobra conventions
func Execute(version string) {
	root.Version = version
	if err := root.Execute(); err != nil {
		log.WithError(err).Error("Error running command")
		os.Exit(1)
	}
}
