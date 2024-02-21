{{if .HasDB}}package repository

import (
	"github.com/jinzhu/gorm"

	"{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/internal/component/example"
)

type GormExampleRepository struct {
	*gorm.DB
}

func NewGormExampleRepository(db *gorm.DB) example.Repository {
	return &GormExampleRepository{
		db.Debug(),
	}
}

func (repo *GormExampleRepository) GetAnExample() error {
	// Implement gorm queries here and in other files in this package.
	panic("Gorm repo not yet implemented")

	return nil
}{{end}}
