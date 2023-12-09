# Examples of using Swift OpenAPI Generator

This directory contains examples of how to use Swift OpenAPI Generator and
integrate with other packages in the ecosystem.

> **Disclaimer:** Many of these examples have been deliberately simplified and are
> intended for illustrative purposes only.

## Getting started

Each of the following packages shows an end-to-end working example with the given transport.



- [hello-world-async-http-client-example](./hello-world-async-http-client-example) - A CLI client using the AsyncHTTPClient library.
- [hello-world-hummingbird-server-example](./hello-world-hummingbird-server-example) - A CLI server using the Hummingbird web framework.
- [hello-world-urlsession-client-example](./hello-world-urlsession-client-example) - A CLI client using the URLSession HTTP client library.
- [hello-world-vapor-server-example](./hello-world-vapor-server-example) - A CLI client using the Vapor web framework.
- [curated-client-library-example](./curated-client-library-example) - A library that hides the generated API and exports a hand-written interface, allowing decoupled versioning.
- [HelloWorldiOSClientAppExample](./HelloWorldiOSClientAppExample) - An iOS client SwiftUI app with mock server for unit and UI tests.

## Various content types

The following packages show working with various content types, such as JSON, URL-encoded request bodies, plain text, raw bytes, and multipart bodies.

- [various-content-types-client-example](./various-content-types-client-example) - A client showing how to request and handle the various content types.
- [various-content-types-server-example](./various-content-types-server-example) - A server showing how to handle and provide the various content types.

## Integrations

- [swagger-ui-endpoint-example](./swagger-ui-endpoint-example) - A server with endpoints its raw OpenAPI document and Swagger UI.
- [postgres-database-example](./postgres-database-example) - A server using a Postgres database for persistent state.
- [command-line-client-example](./command-line-client-example) - A client with a rich CLI using Swift Argument Parser.

## Middleware

- [logging-middleware-oslog-example](./logging-middleware-oslog-example) - A middleware that logs requests and responses using OSLog.
- [logging-middleware-swift-log-example](./logging-middleware-swift-log-example) - A middleware that logs requests and responses using Swift Log.
- [metrics-middleware-example](./metrics-middleware-example) - A middleware that collects metrics using Swift Metrics.
- [tracing-middleware-example](./tracing-middleware-example) - A middleware that collects traces using Swift Distributed Tracing.
- [retrying-middleware-example](./retrying-middleware-example) - A middleware that retries failed requests.
- [auth-client-middleware-example](./auth-client-middleware-example) - An middleware that injects a token header.
- [auth-server-middleware-example](./auth-server-middleware-example) - An middleware that inspects a token header.

## Ahead-of-time (manual) code generation

The recommended way to use Swift OpenAPI generator is by integrating the _build plugin_, which all of the examples above use. The build plugin generates Swift code from your OpenAPI document at build time, and you don't check in the generated code into git. 

However, if you cannot use the build plugin, for example because you must check in your generated code, use the _command plugin_, which you trigger manually either in Xcode or on the command line. See the following example for this workflow:

- [manual-generation-package-plugin-example](./manual-generation-package-plugin-example) - A client using the Swift package plugin for manual code generation.

If you can't even use the command plugin, for example because your package is not allowed to depend on swift-openapi-generator directly, you can invoke the generator CLI manually from a Makefile. See the following example for this workflow:

- [manual-generation-generator-cli-example](./manual-generation-generator-cli-example) - A client using the `swift-openapi-generator` CLI for manual code generation.

## Deprecated

The following examples will be removed before 1.0.0 is released and is preserved for backwards compatibility with currently published tutorials that point to it.

- [`GreetingService`](./GreetingService) - a Vapor-based CLI server, use `HelloWorldVaporServer` instead
- [`GreetingServiceClient`](./GreetingServiceClient) - a URLSession-based CLI client, use `HelloWorldURLSessionClient` instead
