package cmd

import (
	"errors"
	"regexp"
	"strings"

	"github.com/gosimple/slug"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"

	"gitlab.com/amihan/common/tooling/go-bootstrapper/internal/eval"
	"gitlab.com/amihan/common/tooling/go-bootstrapper/internal/interactions"
	"gitlab.com/amihan/common/tooling/go-bootstrapper/internal/persistence"
)

var (
	generateCommand = &cobra.Command{
		Use:       "generate {microservice}",
		Short:     "Generate project",
		Run:       runGenerate,
		Args:      cobra.ExactValidArgs(1),
		ValidArgs: []string{"microservice"},
	}
	projectName, projectSlug, projectGroup, gitHost, projectVersion string
	hasDB, hasMessageBus, hasJWT, hasAPIKey                         bool
)

const (
	defaultGitHost        = "gitlab.com"
	defaultProjectGroup   = "amihan"
	defaultProjectVersion = "0.0.1"
)

func init() {
	generateCommand.Flags().StringVar(&gitHost, "git-host", "", "Remote git host. This will be used as the root for go modules.")
	generateCommand.Flags().StringVar(&projectGroup, "project-group", "", "The group hierarchy of the project. Ex. amihan/common/libraries/go.")
	generateCommand.Flags().StringVar(&projectName, "project-name", "", "The human readable name of the project to generate")
	generateCommand.Flags().StringVar(&projectSlug, "project-slug", "", "Slug name for the project to generate. This will be used as the project identifier.")
	generateCommand.Flags().StringVar(&projectVersion, "project-version", "", "Version of the project to generate.")
	generateCommand.Flags().BoolVar(&hasDB, "has-database", false, "The project uses a database")
	generateCommand.Flags().BoolVar(&hasMessageBus, "has-messagebus", false, "The project uses a messagebus")
	generateCommand.Flags().BoolVar(&hasJWT, "has-jwt", false, "The project uses JWT")
	generateCommand.Flags().BoolVar(&hasAPIKey, "has-api-key", false, "The project uses API Keys")

	root.AddCommand(generateCommand)
}

func runGenerate(c *cobra.Command, args []string) {
	log.Info("========================================")
	log.Info("Generating golang project")
	log.Info("========================================")

	if err := evalProperty(&gitHost, "Git Host", defaultGitHost, "^[a-z]+[a-z0-9-\\.]*[a-z]$",
		"Invalid git host. It must be a valid domain name."); err != nil {
		return
	}

	if err := evalProperty(&projectGroup, "Project Group", defaultProjectGroup, "^[a-z]+[a-z0-9-\\./]*[a-z0-9]$",
		"Invalid project group. It must be a path."); err != nil {
		return
	}

	if err := evalProperty(&projectName, "Project Name", "", "^[A-Za-z][A-Za-z0-9 ]*[A-Za-z0-9]$",
		"Invalid project name. It must start with a letter and contain only letters, numbers and spaces"); err != nil {
		return
	}

	defaultSlug := slug.Make(projectName)
	if err := evalProperty(&projectSlug, "Project Slug", defaultSlug, "^[a-z][a-z0-9-]*[a-z0-9]$",
		"Invalid project slug. It must start with a lower case letter, end with a lower-case letter or a number and contain only letters, numbers and dashes."); err != nil {
		return
	}

	if err := evalProperty(&projectVersion, "Project Version", defaultProjectVersion, "^[0-9]+\\.[0-9]+\\.[0-9]+$",
		"Invalid project version. It must be a semantic version."); err != nil {
		return
	}

	log.Infof(`Starting to generate boiler plate:
        * Git Host: %s,
		* Project Group: %s, 
		* Project Name: %s,
		* Project Slug: %s
		* Project Version: %s`,
		gitHost, projectGroup, projectName, projectSlug, projectVersion)

	type Context struct {
		GitHost, ProjectGroup, ProjectName, ProjectSlug, ProjectVersion, ProjectEnvPrefix string
		HasDB, HasMessageBus, HasJWT, HasAPIKey                                           bool
	}

	filesToGenerate, contents := eval.EvaluateTemplates(args[0],
		Context{gitHost, projectGroup, projectName, projectSlug, projectVersion,
			strings.ReplaceAll(strings.ToUpper(projectSlug), "-", "_"),
			hasDB, hasMessageBus, hasJWT, hasAPIKey})

	if len(filesToGenerate) != len(contents) {
		log.Error("Invalid results from template evaluation aborting.")
		return
	}

	fileContents := make([]persistence.FileContent, len(filesToGenerate))
	for i := range filesToGenerate {
		fileContents[i] = persistence.FileContent{
			Path:    filesToGenerate[i],
			Content: contents[i],
		}
	}
	persistence.Persist(projectSlug, fileContents)

}

func evalProperty(property *string, label, defaultVal, regex, errorMsg string) (err error) {
	if *property == "" {
		var userInput string
		userInput, err = interactions.UserInput(label, defaultVal)
		if err != nil {
			log.Error(errorMsg)
			return
		}
		*property = userInput
	}

	if regex != "" {
		var matched bool
		matched, err = regexp.MatchString(regex, *property)
		if !matched {
			log.Error(errorMsg)
			err = errors.New("User input does not match acceptable format")
		}
	}
	return
}
