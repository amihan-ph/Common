package example

import (
	"github.com/gorilla/mux"
	
	{{if .HasJWT}}
	jwtAuth "gitlab.com/amihan/common/libraries/go/jwt-auth.git"
	{{end}}
	{{if .HasAPIKey}}
	apiKeyAuth "gitlab.com/amihan/common/libraries/go/api-key-auth.git"
	{{end}}

	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/component/example"
	{{- if and .HasJWT .HasAPIKey}}
	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/infrastructure/auth"
	{{end}}
)

// Controller is the REST controller
type Controller struct {
	exampleService example.Service
}

// NewController creates a new Controller
func NewController(exampleService example.Service) *Controller {
	return &Controller{
		exampleService,
	}
}

// Register registers the endpoints to the router
func (c *Controller) Register(router *mux.Router{{if .HasAPIKey}}, apiKeyAuthMiddleware *apiKeyAuth.APIKeyAuthorize{{end}}{{if .HasJWT}}, jwtAuthMiddleware *jwtAuth.JWT{{end}}{{if and .HasJWT .HasAPIKey}}, attributeAuthMiddleware *auth.AttributeAuthorize{{end}}) {
	example := router.PathPrefix("/accounts").Subrouter()
	exampleService := c.exampleService

	// No auth
	example.
		Path("/no-auth").
		HandlerFunc(getNoAuthHandler(exampleService))
	{{- if .HasJWT}}
	
	// JWT auth
	example.
		Path("/jwt").
		HandlerFunc(jwtAuthMiddleware.ValidateMiddleware(getJWTAuthHandler(exampleService)))
	{{end}}
	{{- if .HasAPIKey}}
	
	// API Key required auth
	example.
		Path("/api-key-required").
		HandlerFunc(apiKeyAuthMiddleware.AuthorizeOnRequiredAPIKeyMiddleware(getAPIKeyRequiredHandler(exampleService)))
	{{end}}
	{{- if and .HasJWT .HasAPIKey}}
	
	// Either API Key or JWT auth
	example.
		Path("/either-api-key-or-jwt").
		HandlerFunc(apiKeyAuthMiddleware.AuthorizeOnAPIKeyMiddleware(
			getEitherAPIKeyOrJWTHandler(exampleService),
			jwtAuthMiddleware.ValidateMiddleware))

	// Authorize on claim attribute from JWT
	example.
		Path("/authorize-on-jwt-claim-attribute").
		HandlerFunc(apiKeyAuthMiddleware.AuthorizeOnAPIKeyMiddleware(
			getAuthorizeOnJWTClaimAttribute(exampleService),
			jwtAuthMiddleware.ValidateMiddleware, attributeAuthMiddleware.AuthorizeOnAttributeMiddleware))
	{{end}}
}
{{- if .HasMessageBus}}

func (c *Controller) OnMessageSubscription()  chan interface{} {
	return c.exampleService.OnMessageSubscription()
}
{{end}}
