package rest

import (
	"fmt"
	"net/http"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"
	{{- if or .HasJWT .HasAPIKey}}
	"gopkg.in/yaml.v2"
	{{end}}
	{{- if .HasJWT}}
	
	jwtAuth "gitlab.com/amihan/common/libraries/go/jwt-auth.git"
	{{end}}
	{{if .HasAPIKey}}
	apiKeyAuth "gitlab.com/amihan/common/libraries/go/api-key-auth.git"
	{{end}}

	"gitlab.com/amihan/common/libraries/go/middlewares.git"
	"gitlab.com/amihan/common/libraries/go/responses.git"

	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/entrypoint/api/rest/example"
	{{- if or .HasJWT .HasAPIKey}}	
	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/infrastructure/auth"
	{{end}}
)

type (
	// Config contains the entire configuration of the rest api
	Config struct {
		Host    string
		Port    int
		Spec    string
		Version string
		Cors    CORSConfig
		{{- if or .HasJWT .HasAPIKey}}
		Auth    AuthConfig
		{{end}}
	}
	{{- if or .HasJWT .HasAPIKey}}
	
	// AuthConfig contains auth related configuration
	AuthConfig struct {
		{{- if .HasAPIKey}}
		APIKey           string
		APIKeyParamName  string
		{{end}}
		{{- if .HasJWT}}
		JWTPubKeyURL     string
		{{- if .HasAPIKey}}
		ClaimsAttribute  string		
		RequestParamName string
		{{end}}
		{{end}}
		RBACFile         string
		RBAC             string		
	}
	{{end}}

	// CORSConfig contains CORS related configuration
	CORSConfig struct {
		AllowedOrigins []string
		AllowedHeaders []string
		AllowedMethods []string
	}

	// API is the top level struct of the REST API implementation
	API struct {
		config               *Config
		router               *mux.Router
		exampleController    *example.Controller
	}
)

// NewRestAPI will create and return and instance of the API struct
func NewRestAPI(config *Config, router *mux.Router, exampleController *example.Controller) *API {
	return &API{
		config:               config,
		router:               router,
		exampleController:    exampleController,
	}
}

// Run will configure, start and serve the REST API and it the services it depends on.
func (api *API) Run() {{- if .HasMessageBus}} ([]chan interface{}, error){{else}} error{{end}} {
	api.router = api.router.PathPrefix("/api/v1").Subrouter()
	api.registerHandlers()
	api.exposeSwagger()
	api.exposeVersion()
	api.exposeHealth()
	api.addMiddlewares()
	api.enableCORS()
	return {{- if .HasMessageBus}} api.runKafkaListeners(),{{end}} http.ListenAndServe(api.address(), api.router)
}

func (api *API) address() string {
	return fmt.Sprintf("%s:%d", api.config.Host, api.config.Port)
}

func (api *API) exposeSwagger() {
	api.router.HandleFunc("/spec", func(res http.ResponseWriter, req *http.Request) {
		http.ServeFile(res, req, api.config.Spec)
	})
	log.Infof("OpenAPI Spec accessible at http://%s/api/v1/spec", api.address())
}

func (api *API) exposeVersion() {
	api.router.HandleFunc("/version", func(res http.ResponseWriter, req *http.Request) {
		responses.WriteOKWithEntity(res, api.config.Version)
	})
}

func (api *API) exposeHealth() {
	api.router.HandleFunc("/health", func(res http.ResponseWriter, req *http.Request) {
		responses.WriteOK(res)
	})
}

func (api *API) enableCORS() {
	cors := handlers.CORS(
		handlers.AllowedOrigins(api.config.Cors.AllowedOrigins),
		handlers.AllowedHeaders(api.config.Cors.AllowedHeaders),
		handlers.AllowedMethods(api.config.Cors.AllowedMethods),
	)
	api.router.Use(cors)
}

func (api *API) addMiddlewares() {
	logger := middlewares.Logger(log.StandardLogger())
	api.router.Use(logger)
	log.Info("Logger filter enabled")
	// TODO add JWT filter here
}

func (api *API) registerHandlers() {
	{{- if .HasJWT}}
	jwtAuthMiddleware := &jwtAuth.JWT{
		PubKeyURL: api.config.Auth.JWTPubKeyURL,
	}
	{{end}}
	{{- if .HasAPIKey}}
	{{- if .HasJWT}}	
	attributeAuthMiddleware := &auth.AttributeAuthorize{
		ClaimsAttribute:  api.config.Auth.ClaimsAttribute,
		RequestParamName: api.config.Auth.RequestParamName,
	}	
	{{end}}
	apiKeyAuthMiddleware := &apiKeyAuth.APIKeyAuthorize{
		APIKey:          api.config.Auth.APIKey,
		APIKeyParamName: api.config.Auth.APIKeyParamName,
	}
	{{end}}
	{{- if or .HasJWT .HasAPIKey}}
	
	err := yaml.Unmarshal([]byte(api.config.Auth.RBAC), &jwtAuthMiddleware.RBAC)
	if err != nil {
		log.Errorf("Error decoding RBAC: %v", err.Error())
	}
	{{end}}

	api.exampleController.Register(api.router{{if .HasAPIKey}}, apiKeyAuthMiddleware{{end}}{{if .HasJWT}}, jwtAuthMiddleware{{end}}{{if and .HasJWT .HasAPIKey}}, attributeAuthMiddleware{{end}})

}
{{- if .HasMessageBus}}

func (api *API) runKafkaListeners() []chan interface{} {
	log.Printf("running kafka listeners")

	return []chan interface{}{
		api.exampleController.OnMessageSubscription(),
		// Add kafka subscriptions here so that they can get cleaned up on shutdown.
	}
}
{{end}}
