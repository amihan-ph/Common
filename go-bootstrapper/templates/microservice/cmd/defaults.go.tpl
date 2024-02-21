package cmd

import (
	{{- if .HasMessageBus}}
	"time"

	{{end}}
	"github.com/spf13/viper"
)

var defaults = map[string]interface{}{
	"log.level": "debug",

	"api.rest.host":                "0.0.0.0",
	"api.rest.port":                8080,
	"api.rest.spec":                "./openapi.yaml",
	"api.rest.cors.allowedOrigins": []string{"*"},
	"api.rest.cors.allowedHeaders": []string{
		"Content-Type",
		"Sec-Fetch-Dest",
		"Referer",
		"accept",
		"Sec-Fetch-Mode",
		"Sec-Fetch-Site",
		"User-Agent",
		"API-KEY",
		"Authorization",
	},
	"api.rest.cors.allowedMethods": []string{
		"OPTIONS",
		"GET",
		"POST",
		"PUT",
		"DELETE",
	},

	// Secrets file for setting credentials in environments
	"secrets.file": "config/secrets.json",
	{{- if .HasDB}}

	// database configuration
	"datasource.type":       "postgres",
	"datasource.host":       "localhost",
	"datasource.port":       5432,
	"datasource.database":   "<PUT-DATABASE-NAME-HERE>",
	"datasource.username":   "<PUT-DATABASE-USERNAME-HERE>",
	"datasource.password":   "<PUT-DATABASE-PASSWORD-HERE>",
	"datasource.sslMode":    "disable",
	"datasource.migrations": "db/migrations",
	{{end}}
	{{- if .HasMessageBus}}

	// kafka config
	"kafka.brokers":           []string{"<PUT-KAFKA-HOST-HERE>:9092"},
	"kafka.groupID":           "safePassID",
	"kafka.partition":         0,
	"kafka.minBytes":          10240,
	"kafka.maxBytes":          10485760,
	"kafka.commitInterval":    5 * time.Millisecond,
	"kafka.asyncSubscription": true,
	"kafka.asyncRoutines":     10,
	{{end}}
	{{- if .HasJWT}}

	// Basic JWT auth config
	"api.rest.auth.jwtPubKeyUrl": "https://<PUT-KEYCLOAK-HOSTNAME-HERE>/auth/realms/<PUT-REALM-NAME-HERE>",
	{{- if .HasAPIKey}}
	"api.rest.auth.claimsAttribute":  "<PUT-ATTRIBUTE-IN-CLAIM-THAT-IDENTIFIES-THE-USER-HERE>",
	"api.rest.auth.requestParamName": "<PUT-NAME-OF-PARAMETER-THAT-IDENTIFIES-THE-OWNER-OF-RESOURCES-HERE>",
	{{end}}
	{{end}}
	{{- if .HasAPIKey}}

	// Auth via a passed API key
	"api.rest.auth.apiKeyParamName":  "API-KEY",
	{{end}}
	{{- if or .HasJWT .HasAPIKey}}

	// RBAC configuration
	"api.rest.auth.rbacFile":     "config/rbac.yaml",
	{{end}}

	// Put custom configuration here
}

func init() {
	for key, value := range defaults {
		viper.SetDefault(key, value)
	}
}
