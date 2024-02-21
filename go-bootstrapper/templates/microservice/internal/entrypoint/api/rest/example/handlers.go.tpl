package example

import (
	"net/http"

	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"
	"gitlab.com/amihan/common/libraries/go/responses.git"

	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/component/example"
)

func getNoAuthHandler(exampleService example.Service) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		log.Debugf("GET no auth handler called", mux.Vars(req))
		responses.WriteOK(res)
	}
}
{{- if .HasJWT}}

func getJWTAuthHandler(exampleService example.Service) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		log.Debugf("GET jwt auth handler called", mux.Vars(req))
		responses.WriteOK(res)
	}
}
{{end}}
{{- if .HasAPIKey}}

func getAPIKeyRequiredHandler(exampleService example.Service) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		log.Debugf("GET api key required handler called", mux.Vars(req))
		responses.WriteOK(res)
	}
}
{{end}}
{{- if and .HasJWT .HasAPIKey}}

func getEitherAPIKeyOrJWTHandler(exampleService example.Service) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		log.Debugf("GET either api key or JWT handler called", mux.Vars(req))
		responses.WriteOK(res)
	}
}

func getAuthorizeOnJWTClaimAttribute(exampleService example.Service) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		log.Debugf("GET auth on JWT claim handler called", mux.Vars(req))
		responses.WriteOK(res)
	}
}
{{end}}


	
