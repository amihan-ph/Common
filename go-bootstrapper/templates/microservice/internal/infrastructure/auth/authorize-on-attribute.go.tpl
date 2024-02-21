{{if and .HasJWT .HasAPIKey}}package auth

import (
	"fmt"
	"net/http"

	"github.com/dgrijalva/jwt-go"
	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"

	"gitlab.com/amihan/common/libraries/go/responses.git"
)

// Simplistically checks that the caller has access to the identified entity.
// This check is done by matching an attribute in 'claims' from the context to a request parameter
// Note that this assumes that a cooperating middleware has injected the attribute into the context (jwt-auth does this)
// TODO: This probably should be extracted into a library.
type AttributeAuthorize struct {
	ClaimsAttribute  string `json:"claimsAttribute"`
	RequestParamName string `json:"requestParamName`
}

func (auth *AttributeAuthorize) AuthorizeOnAttributeMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		claims, ok := req.Context().Value("claims").(jwt.MapClaims)
		if !ok {
			log.Debugf("Access denied. Claims not found in request of type %T.", req.Context().Value("claims"))
			responses.WriteUnauthorizedError(res)
			return
		}
		claimsAtt, ok := claims[auth.ClaimsAttribute].(string)
		// Note that empty strings are ok as there are assumed to be no objects that can be retrieved using an empty id.
		if !ok {
			// The id may be stored as a float try that
			claimsAttRetry, ok := claims[auth.ClaimsAttribute].(float64)
			if !ok {
				// Claims not present, not authorized
				log.Debugf("Access denied. Claim attribute (%s) not present or has wrong type.", auth.ClaimsAttribute)
				for k := range claims {
					log.Debugf("Found key %s with value %s with type %[2]T", k, claims[k])
				}
				responses.WriteUnauthorizedError(res)
				return
			} else {
				claimsAtt = fmt.Sprintf("%d", uint64(claimsAttRetry))
			}
		}
		vars := mux.Vars(req)
		reqAtt, ok := vars[auth.RequestParamName]
		// The presence of the request parameter means that we looking for a protected resource. Otherwise pass through.
		if ok {
			// Finally check that they match. If not then the request is not authorized
			if reqAtt != claimsAtt {
				log.Debugf("Access denied. Expected %s but got %s as a parameter", claimsAtt, reqAtt)
				responses.WriteUnauthorizedError(res)
				return
			} else {
				log.Debugf("Authorized. Expected value %s and got %s", claimsAtt, reqAtt)
			}
		}

		next(res, req)
	})
}{{end}}
