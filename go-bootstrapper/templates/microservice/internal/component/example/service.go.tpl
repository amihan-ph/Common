package example

import (
	{{- if .HasMessageBus}}
	"gitlab.com/amihan/common/libraries/go/messagebus.git"
	{{end}}
)

type DefaultExampleService struct {
	{{- if .HasDB}}
	exampleRepository Repository
	{{end}}
	{{- if .HasMessageBus}}
	messBus messagebus.Bus
	{{end}}
}

// Factory method for creating an example service
func NewDefaultExampleService({{if .HasDB}}exampleRepository Repository{{end}}{{if .HasMessageBus}}{{if .HasDB}}, {{end}}messBus messagebus.Bus{{end}}) Service {
	return &DefaultExampleService{
		{{- if .HasDB}}
		exampleRepository: exampleRepository,
		{{end}}
		{{- if .HasMessageBus}}		
		messBus:           messBus,
		{{end}}
	}
}

func (s *DefaultExampleService) GetAnExample() error {
	{{- if .HasDB}}
	s.exampleRepository.GetAnExample()
	{{end}}
	{{- if .HasMessageBus}}
	s.messBus.Publish("topic-to-publish", []byte("message"))
	{{end}}
	return nil
}
{{- if .HasMessageBus}}

func (s *DefaultExampleService) OnMessageSubscription() chan interface{} {
	return s.messBus.Subscribe("topic-to-subscribe", func(msg []byte) error {
		return nil
	})
}
{{end}}
	
