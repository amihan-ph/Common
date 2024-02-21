// Put secrets here
{
    {{- if .HasDB}}
    "db-username": "<PUT_DB_USERNAME_HERE>",
    "db-password": "<PUT_DB_PASSWORD_HERE>",
    {{end}}
    {{- if .HasAPIKey}}
    "auth-api-key": "example-api-key-change-this"
    {{end}}
}
