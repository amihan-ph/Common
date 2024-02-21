{{- if or .HasJWT .HasAPIKey}}---
- role: admin
  endpoints:
  - method: POST
    path: "/*"
  - method: GET
    path: "/*"
  - method: PUT
    path: "/*"{{end -}}