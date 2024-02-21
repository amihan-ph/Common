openapi: 3.0.0
info:
  title: {{ .ProjectName }} API
  description: API endpoints for {{ .ProjectName }}
  version: "{{ .ProjectVersion }}"
tags:
  - name: {{ .ProjectSlug }}
    description: Endpoints for {{ .ProjectName }}
security:
  - apiKeyAuth: []
  - bearerAuth: []

paths:
  /api/v1/version:
    summary: Returns the current version
    get:
      tags:
        - {{ .ProjectSlug }}
      responses:
        200:
          description: The API version
          content:
            application/json:
              schema:
                type: object
                properties:
                  version:
                    type: string
                    example: '1.0'
        default:
          $ref: '#/components/responses/jsonError'

  /api/v1/health:
    summary: Health check
    get:
      tags:
        - {{ .ProjectSlug }}
      responses:
        200:
          description: An empty response body.
          content:
            application/json:
              schema:
                type: object
                properties:
                  version:
                    type: string
                    example: '1.0'
        default:
          $ref: '#/components/responses/jsonError'

components:
  securitySchemes:
    apiKeyAuth:
      type: apiKey
      in: header
      name: API-KEY
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  responses:
    jsonError:
      description: >-
        A detailed JSON errors will be returned when there's an issue calling the
        endpoint.
      content:
        application/json:
          schema:
            type: array
            items:
              allOf:
                - $ref: '#/components/schemas/Error'
  schemas:
    Error:
      description: >-
        A JSON Error encapsulates the error returned from an endpoint to a standard error object.
      type: object
      properties:
        id:
          type: string
          description: >-
            a unique identifier for this particular occurrence of the problem.
        links:
          type: object
          description: >-
            a links object containing the following members;
          properties:
            about:
              type: string
              description: >-
                a link that leads to further details about this particular occurrence of the problem.
          additionalProperties: true
        status:
          type: string
          description: >-
            the HTTP status code applicable to this problem, expressed as a
            string value.
        code:
          type: string
          description: >-
            an application-specific error code, expressed as a string value.
        title:
          type: string
          description: >-
            a short, human-readable summary of the problem that SHOULD NOT
            change from occurrence to occurrence of the problem, except for
            purposes of localization.
        detail:
          type: string
          description: >-
            a human-readable explanation specific to this occurrence of the
            problem. Like title, this field’s value can be localized.
        source:
          type: array
          description: >-
            an object containing references to the source of the error,
            optionally including any of the following members;
          items:
            type: object
            properties:
              pointer:
                type: string
                description: >-
                  a JSON Pointer [RFC6901] to the associated entity in the
                  request document [e.g. "/data" for a primary data object, or "
                  /data/attributes/title" for a specific attribute].
              parameter:
                type: string
                description: >-
                  a string indicating which parameter caused the error.
        meta:
          type: object
          description: >-
            a meta object containing non-standard meta-information about the error.
          additionalProperties: true
