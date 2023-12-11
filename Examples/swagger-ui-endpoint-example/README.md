# Server with OpenAPI document and Swagger UI endpoints

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A server that shows setting up endpoints that serve the OpenAPI document and also a web page with the rendered documentation, respectively. It also uses generated server stubs to handle requests as the Greeting Service.

The documentation viewer uses [swagger-ui](https://github.com/swagger-api/swagger-ui).

Note that the `openapi.yaml` file is now in the `Public` directory, served by the `FileMiddleware` automatically.

And the Sources directory of the server target contains a symlink to the file above, to avoid having two copies of the OpenAPI document that could get out of sync.

The OpenAPI document also contains the following server definition, which allows making HTTP requests directly from the documentation viewer served at `http://localhost:8080/openapi`.

```yaml
  - url: /api
    description: This server.
```

The tool uses the [Vapor](https://github.com/vapor/vapor) server framework to handle HTTP requests, wrapped in the [Swift OpenAPI Vapor Transport](https://github.com/swift-server/swift-openapi-vapor).

The CLI starts the server on `http://localhost:8080` and you can go to `http://localhost:8080/openapi.yaml` to see the raw OpenAPI document, and to `http://localhost:8080/openapi` to see the rendered documentation.

## Usage

Build and run the server CLI using:

```console
% swift run
2023-12-01T14:14:35+0100 notice codes.vapor.application : [Vapor] Server starting on http://127.0.0.1:8080
...
```

Then go to `https://localhost:8080/openapi` in your web browser.
