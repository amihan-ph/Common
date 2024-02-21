package cmd

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	{{- if .HasMessageBus}}

	sync "gitlab.com/amihan/common/libraries/go/sync.git"
	{{end}}
)

var serve = &cobra.Command{
	Use:   "serve",
	Short: "run the server",
	Run:   runServe,
}

func init() {
	root.AddCommand(serve)
}

func runServe(c *cobra.Command, args []string) {
	{{if .HasDB}}runMigrate(c, args){{end}}
	log.Info("========================================")
	log.Info("{{ .ProjectName }}")
	log.Info("========================================")

	setLogLevel()

	restAPI := createRestAPI()

	log.Info("========================================")
	log.Info("Starting API Server")
	log.Info("========================================")
	
        {{if .HasMessageBus}}kafkaListeners, {{end}}err := restAPI.Run()
	
	if err != nil {
		log.WithError(err).Error("REST API terminated")
        }
	{{- if .HasMessageBus}}

	sync.WaitForInterrupt(func() error {
		for _, listener := range kafkaListeners {
			close(listener)
		}
		return nil
	})
	{{end}}
}

func setLogLevel() {
	logLevel := viper.GetString("log.level")
	level, err := log.ParseLevel(logLevel)
	if err != nil {
		log.WithError(err).Errorf("log level %s is invalid", logLevel)
	}
	log.SetLevel(level)
	log.Infof("Log Level Set to: %s", level)
}
