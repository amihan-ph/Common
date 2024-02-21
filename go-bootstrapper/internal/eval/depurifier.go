package eval

import (
	"fmt"
	"os"
	"strings"
)

// depurify will revert purification filters done on the paths by pkger
// github.com/markbates/pkger will "purify" file paths by replacing any occurrences of
// the values of $HOME, $GOROOT and $GOPATH environment variables.
// Ex. if $GOPATH is /go a path to proj/go.mod will get replaced with proj$GOPATH.mod.
// Since the above path evaluation doesn't suit our needs it is reverted here.
func depurify(path string) (depurifiedPath string) {
	envsToRevert := []string{"HOME", "GOROOT", "GOPATH"}

	depurifiedPath = path

	for _, envVar := range envsToRevert {
		if envValue, ok := os.LookupEnv(envVar); ok {
			depurifiedPath = strings.ReplaceAll(depurifiedPath, fmt.Sprintf("$%s", envVar), envValue)
		}
	}
	return
}
