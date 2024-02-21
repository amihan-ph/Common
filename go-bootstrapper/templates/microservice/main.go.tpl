package main

import "{{ .GitHost }}/{{ .ProjectGroup }}/{{ .ProjectSlug }}/cmd"

var version = "{{ .ProjectVersion }}"

func main() {
	cmd.Execute(version)
}
