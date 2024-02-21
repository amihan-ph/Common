package persistence

import (
	"os"
	"path/filepath"

	log "github.com/sirupsen/logrus"
)

// FileContent describes a file and its contents.
// FileContents are used as instructions to generate the project.
// Path is where the file will get created and Content is the contents of the file.
type FileContent struct {
	Path, Content string
}

// Persist will create the files with paths relative to path
// If path already exists Persist will return without creating anything.
func Persist(path string, fileContents []FileContent) {
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		log.Errorf("Can't create project in %s as that location already exists", path)
		return
	}

	log.Infof("Creating project directory %s", path)
	os.MkdirAll(path, os.ModePerm)

	for _, fileContent := range fileContents {
		fullPath := filepath.Join(path, fileContent.Path)
		dir := filepath.Dir(fullPath)
		if _, err := os.Stat(dir); os.IsNotExist(err) {
			log.Debugf("Directory %s for file does not yet exist. Creating it.", dir)
			os.MkdirAll(dir, os.ModePerm)
		}

		f, err := os.Create(fullPath)
		if err != nil {
			log.WithError(err).Errorf("Could not create file %s. Aborting.", fullPath)
			return
		}
		defer f.Close()
		f.Write([]byte(fileContent.Content))
	}
}
