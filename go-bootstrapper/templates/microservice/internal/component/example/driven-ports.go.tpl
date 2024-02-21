package example

// Declare the interfaces that the services in this domain interact with here. These are typically repositories but could be other infrastructure related components such as payment gateways, sms gateways, etc..
{{- if .HasDB}}

type Repository interface {
	GetAnExample() error
}
{{end}}


