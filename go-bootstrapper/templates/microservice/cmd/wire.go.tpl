//+build wireinject

package cmd

import (
	"encoding/json"
	"io/ioutil"
	"os"

	"github.com/google/wire"
	"github.com/gorilla/mux"
	{{- if .HasDB}}
	"github.com/jinzhu/gorm"
	{{end}}
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	{{- if .HasMessageBus}}

	"gitlab.com/amihan/common/libraries/go/messagebus.git"
	{{end}}

	// REST endpoints
	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/entrypoint/api/rest"

        //service components
	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/component/example"
	{{- if .HasDB}}
	
	//repository
	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/infrastructure/postgres"
	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/infrastructure/postgres/repository"
	{{end}}

	//controllers
	exampleHandlers "{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/entrypoint/api/rest/example"
)

type Keys struct {
	{{- if .HasDB}}
	DBUsername string `json:"db-username"`
	DBPassword string `json:"db-password"`
	{{end}}
	{{- if .HasAPIKey}}
	APIKey     string `json:"api-key"`
	{{end}}
}

func createRestAPI() *rest.API {
	wire.Build(
		// services
		example.NewDefaultExampleService,
		{{- if .HasDB}}
		
		// DB repository 
		repository.NewGormExampleRepository,
		{{end}}

		// handlers
		exampleHandlers.NewController,

		// rest
		mux.NewRouter,
		ProvideRestAPIConfig,
		rest.NewRestAPI,

		// Allow configration of credentials from file
		ProvideKeysFromFile,
		{{- if .HasDB}}

		// database
		ProvideDatasource,
		ProvideGormDB,
		{{end}}
		{{- if .HasMessageBus}}

		// Message bus
		ProvideKafkaConfig,
		messagebus.NewKafka,
		{{end}}
		// Put other factory method references here
	)
	return &rest.API{}
}

func ProvideRestAPIConfig(keys *Keys) *rest.Config {
	var config rest.Config
	err := viper.UnmarshalKey("api.rest", &config)
	if err != nil {
		log.WithError(err).Error("unable to read RestAPIConfig")
		os.Exit(1)
	}
	{{- if or .HasJWT .HasAPIKey}}
	
	rbacData, err := ioutil.ReadFile(config.Auth.RBACFile)
	if err != nil {
		log.WithError(err).Error("Error in reading RBAC data")
	}

	config.Auth.RBAC = string(rbacData)
	{{end}}
	{{- if .HasAPIKey}}
	
	config.Auth.APIKey = keys.APIKey
	{{end}}

	config.Version = root.Version

	log.Info("========================================")
	log.Info("API Configuration")
	log.Info("========================================")
	log.Info("Host:    ", config.Host)
	log.Info("Port:    ", config.Port)
	log.Info("Spec:    ", config.Spec)
	log.Info("Version: ", config.Port)

	log.Debugf("API Config: %+v", config)
	return &config
}
{{- if .HasDB}}

func createMigration() *postgres.Migration {
	wire.Build(
		ProvideKeysFromFile,
		ProvideDatasource,
		postgres.NewMigration,
	)
	return &postgres.Migration{}
}

func ProvideDatasource(keys *Keys) *postgres.Datasource {
	var datasource postgres.Datasource
	err := viper.UnmarshalKey("datasource", &datasource)
	if err != nil {
		log.WithError(err).Error("unable to read Datasource config")
		os.Exit(1)
	}
	datasource.Username = keys.DBUsername
	datasource.Password = keys.DBPassword
	return &datasource
}

func ProvideGormDB(datasource *postgres.Datasource) *gorm.DB {
	db, err := gorm.Open("postgres", datasource.AsPQString())
	if err != nil {
		log.WithError(err).Error("unable to get gorm db connection")
		os.Exit(1)
	}
	return db
}
{{end}}

func ProvideKeysFromFile() *Keys {
	file := viper.GetString("secrets.file")
	jsonFile, err := os.Open(file)
	if err != nil {
		log.WithError(err).Error("unable to read security keys file")
		os.Exit(1)
	}
	defer jsonFile.Close()

	byteValue, _ := ioutil.ReadAll(jsonFile)
	var secrets Keys
	json.Unmarshal(byteValue, &secrets)

	return &secrets
}

{{- if .HasMessageBus}}

func ProvideKafkaConfig() *messagebus.KafkaConfig {
	var config messagebus.KafkaConfig
	err := viper.UnmarshalKey("kafka", &config)

	if err != nil {
		log.WithError(err).Error("unable to read Config")
		os.Exit(1)
	}
	return &config
}
{{end}}

// Put other factory function declarations here
