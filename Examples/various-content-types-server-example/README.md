# Server supporting various content types

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A server that uses generated server stubs to show how to work with various HTTP content types. 

The tool uses the [Vapor](https://github.com/vapor/vapor) server framework to handle HTTP requests, wrapped in the [Swift OpenAPI Vapor Transport](https://github.com/swift-server/swift-openapi-vapor).

The CLI starts the server on `http://localhost:8080` and can be invoked by running `various-content-types-client-example` or on the command line using:

```console
% curl http://localhost:8080/api/exampleJSON
{
  "message" : "Hello, Stranger!"
}
```

## Usage

Build and run the server CLI using:

```console
% swift run
2023-12-01T14:14:35+0100 notice codes.vapor.application : [Vapor] Server starting on http://127.0.0.1:8080
...
```

## Testing

Run tests using:

```console
% swift test
```

The testing strategy is to call the `Handler` directly from tests, as it conforms the `APIProtocol` and implements the business logic.

This allows you to provide any input to the handler methods and verify that the correct outputs are returned, such as error responses when the input data is invalid, and so on.

Unit testing of the `Handler` happens without involving any `ServerTransport`, which means that you can change the concrete transport later without changing your tests.
