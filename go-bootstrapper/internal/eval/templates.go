package eval

// This implementation depends on pkger to package the templates with the built binary.
// If you need to add or edit a template run the following commands from the root of this project.
// $ go get github.com/markbates/pkger/cmd/pkger
// $ pkger -include /templates -o internal/eval
// IMPORTANT NOTE: There's a bug in pkger that causes all files that start with the the value of $GOPATH to $GOPATH
//  If the generated project has files with names that start with $GOPATH check the value of the GOPATH environment variable.

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/markbates/pkger"
	log "github.com/sirupsen/logrus"
)

// TemplateRootDir is the path relative to the root of this project where templates are stored
const TemplateRootDir = "/templates"

// TemplateExt is the file extension for templates
const TemplateExt = ".tpl"

// EvaluateTemplates will walk through and evaluate all the templates in subdir
// It will return two slices.
// The first slice contains the path of the template to the subdir.
// The second slice contains the contents of the files.
// Both slices will have the same number of elements and will be appropriately ordered so that paths a[i] correzponds to contents in b[i]
func EvaluateTemplates(subdir string, context interface{}) ([]string, []string) {
	templateRoot := fmt.Sprintf("%s/%s", TemplateRootDir, subdir)

	var filesToCreate, fileContents []string

	f := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.WithError(err).Warn("Error encountered while traversing template directory.")
			return err
		}

		// We can safely ignore folders. This will mean that empty folders will not get created in the project.
		if !info.IsDir() {
			// It's a file we need to evaluate the template then copy the result over.
			file, err := pkger.Open(path)
			if err != nil {
				log.WithError(err).Errorf("Could not open %s", path)
				return err
			}
			defer file.Close()

			contents, _ := ioutil.ReadAll(file)
			var evaluatedContent, fileNameToCreate string
			if isTemplate(info) {
				log.Debugf("Evaluating file %s as a template", path)
				buf := new(bytes.Buffer)
				tpl := template.Must(template.New(path).Parse(string(contents)))
				err := tpl.Execute(buf, context)
				if err != nil {
					log.WithError(err).Error("Failed to execute template. Aborting.")
					return err
				}
				evaluatedContent = buf.String()
				fileNameToCreate = stripTemplateExt(path)
			} else {
				log.Debugf("Copying %s directly to output", path)
				evaluatedContent = string(contents)
				fileNameToCreate = path
			}
			if len(strings.TrimSpace(evaluatedContent)) > 0 {
				filesToCreate = append(filesToCreate, depurify(getRelativePath(fileNameToCreate, templateRoot)))
				fileContents = append(fileContents, evaluatedContent)
			}
		}

		return nil
	}

	pkger.Walk(templateRoot, f)
	return filesToCreate, fileContents
}

func isTemplate(fileInfo os.FileInfo) bool {
	return filepath.Ext(fileInfo.Name()) == TemplateExt
}

func getRelativePath(pkgerPath, templateRoot string) string {
	// Note that this makes the assumption that pkger uses the colon as a marker and
	/// that there are no colons in the paths in the templates folder.
	pathComponents := strings.Split(pkgerPath, ":")
	pathFromRoot := pathComponents[len(pathComponents)-1]

	if strings.HasPrefix(pathFromRoot, templateRoot) {
		return pathFromRoot[len(templateRoot):]
	}
	return pathFromRoot
}

func stripTemplateExt(path string) string {
	return path[0 : len(path)-len(TemplateExt)]
}
