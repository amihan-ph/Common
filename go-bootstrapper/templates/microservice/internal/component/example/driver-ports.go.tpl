package example

// Interface declaration for a service in the 'example' domain.
type Service interface {
	GetAnExample() error
	{{- if .HasMessageBus}}
	OnMessageSubscription() chan interface{}
	{{end}}
}


