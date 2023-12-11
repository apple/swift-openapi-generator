# Auth server middleware

In this example we'll implement a `ServerMiddleware` that verifies an authentication header in the request.

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example extends the [hello-world-vapor-server-example](../hello-world-vapor-server-example)
with a new target, `AuthenticationServerMiddleware`, which is then used when registering the server handler with the transport.

NOTE: This example shows just one way of varifying authentication information in a middleware and is purely for illustrative purposes.

The tool uses the [Vapor](https://github.com/vapor/vapor) server framework to handle HTTP requests, wrapped in the [Swift OpenAPI Vapor Transport](https://github.com/swift-server/swift-openapi-vapor).

The CLI starts the server on `http://localhost:8080` and can be invoked by running the `AuthenticationClientMiddleware` example client or on the command line using:

```console
% curl -H 'Authorization: token_for_Frank' 'http://localhost:8080/api/greet?name=Jane'
{
  "message" : "Hello, Jane! (Requested by: Frank)"
}
```

## Usage

Build and run the server CLI using:

```console
% swift run
2023-12-01T14:14:35+0100 notice codes.vapor.application : [Vapor] Server starting on http://127.0.0.1:8080
...
```
