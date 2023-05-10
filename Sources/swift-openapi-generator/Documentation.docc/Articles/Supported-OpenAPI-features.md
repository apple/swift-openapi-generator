# Supported OpenAPI features

Learn which OpenAPI features are supported by Swift OpenAPI Generator.

## Overview

Swift OpenAPI Generator is currently focused on supporting [OpenAPI 3.0.3][0].

As the project evolves, support may be added [OpenAPI 3.1.0][1].

Supported features are always provided on _both_ client and server.

> Tip: If a feature you need isn't currently supported, let us know by filing an issue, or even contribute a pull request. For more information, check out <doc:Contributing-to-Swift-OpenAPI-Generator>.

### OpenAPI specification features

#### OpenAPI Object

- [x] openapi
- [x] info
- [x] servers
- [x] paths
- [x] components
- [ ] security
- [ ] tags
- [ ] externalDocs

#### Info Object

- [x] title
- [x] description
- [ ] termsOfService
- [ ] contact
- [ ] license
- [x] version

#### Contact Object

- [ ] name
- [ ] url
- [ ] email

#### License Object

- [ ] name
- [ ] url

#### Server Object

- [x] url
- [x] description
- [ ] variables

#### Server Variable Object

- [ ] enum
- [ ] default
- [ ] description

#### Paths Object

- [x] map from pattern to Path Item Object

#### Path Item Object

- [ ] $ref
- [x] summary
- [x] description
- [x] get/put/post/delete/options/head/patch/trace
- [ ] servers
- [x] parameters

#### Operation Object

- [ ] tags
- [x] summary
- [x] description
- [ ] externalDocs
- [x] operationId
- [x] parameters
- [x] requestBody
- [x] responses
- [ ] callbacks
- [ ] deprecated
- [ ] security
- [ ] servers

#### Request Body Object

- [x] description
- [x] content
- [x] required

#### Media Type Object

- [x] schema
- [ ] example
- [ ] examples
- [ ] encoding

#### Security Requirement Object

- [ ] map from name pattern to a list of strings

#### Responses Object

- [x] default
- [x] map of HTTP status code to response

#### Response Object

- [x] description
- [x] headers
- [x] content
- [ ] links

#### Header Object

- [x] a special case of Parameter Object

#### Callback Object

- [ ] map from expression to Path Item Object

#### Schema Object

- [x] title
- [ ] multipleOf
- [ ] maximum
- [ ] exclusiveMaximum
- [ ] minimum
- [ ] exclusiveMinimum
- [ ] maxLength
- [ ] minLength
- [ ] pattern
- [ ] maxItems
- [ ] minItems
- [ ] uniqueItems
- [ ] maxProperties
- [ ] minProperties
- [x] required
- [x] enum
- [x] type
- [x] allOf
    - a wrapper struct is generated and children must be object schemas
- [x] oneOf
    - if a discriminator is specified (recommended), children must be object schemas
    - if no discriminator is specified, children can be any schema
- [x] anyOf
    - children must be object schemas
- [ ] not
- [x] items
- [x] properties
- [x] additionalProperties
- [x] description
- [x] format
- [ ] default
- [ ] nullable
- [x] discriminator
- [ ] readOnly
- [ ] writeOnly
- [ ] xml
- [ ] externalDocs
- [ ] example
- [ ] deprecated

#### External Documentation Object

- [ ] description
- [ ] url

#### Discriminator Object

- [x] propertyName
- [x] mapping

#### XML Object

- [ ] name
- [ ] namespace
- [ ] prefix
- [ ] attribute
- [ ] wrapped

#### Encoding Object

- [ ] contentType
- [ ] headers
- [ ] style
- [ ] explode
- [ ] allowReserved

#### Parameter Object

- [x] name
- [x] in
- [x] description
- [x] required
- [ ] deprecated
- [ ] allowEmptyValue
- [x] style (not all)
- [x] explode (only explode: `true`)
- [ ] allowReserved
- [x] schema
- [ ] example
- [ ] examples
- [ ] content

#### Style Values

- [ ] matrix (in path)
- [ ] label (in path)
- [ ] form (in query)
    - [x] primitive
    - [x] array
    - [ ] object
- [ ] form (in cookie)
- [x] simple (in path)
- [x] simple (in header)
- [ ] spaceDelimited (in query)
- [ ] pipeDelimited (in query)
- [ ] deepObject (in query)

Supported location + styles + exploded combinations:
- path + simple + false
- query + form + true
- header + simple + false

#### Reference Object

- [x] $ref

#### Components Object

- [x] schemas
- [x] responses (always inlined)
- [x] parameters
- [ ] examples
- [x] requestBodies (always inlined)
- [x] headers
- [ ] securitySchemes
- [ ] links
- [ ] callbacks

#### Link Object

- [ ] operationRef
- [ ] operationId
- [ ] parameters
- [ ] requestBody
- [ ] description
- [ ] server

#### Tag Object

- [ ] name
- [ ] description
- [ ] externalDocs

#### Security Scheme Object

- [ ] type
- [ ] description
- [ ] name
- [ ] in
- [ ] scheme
- [ ] bearerFormat
- [ ] flows
- [ ] openIdConnectUrl

#### OAuth Flows Object

- [ ] implicit
- [ ] password
- [ ] clientCredentials
- [ ] authorizationCode

#### OAuth Flow Object

- [ ] authorizationUrl
- [ ] tokenUrl
- [ ] refreshUrl
- [ ] scopes

#### Specification Extensions

- no specific extensions supported

[0]: https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md
[1]: https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md
