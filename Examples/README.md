# Examples of using Swift OpenAPI Generator

This directory contains examples of how to use and
integrate Swift OpenAPI Generator with other packages in the ecosystem.

> Important: Many of these examples have been deliberately simplified and are intended for illustrative purposes only.

All the examples can be found in the [Examples](https://github.com/apple/swift-openapi-generator/tree/main/Examples) directory of the [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator) repository.

To run an example locally, for example [hello-world-urlsession-client-example](https://github.com/apple/swift-openapi-generator/tree/main/Examples/hello-world-urlsession-client-example), clone the Swift OpenAPI Generator repository, and run the example, as shown below:

```console
% git clone https://github.com/apple/swift-openapi-generator
% cd swift-openapi-generator/Examples
% swift run --package-path hello-world-urlsession-client-example
```

## Getting started

Each of the following packages shows an end-to-end working example with the given transport.

- [hello-world-urlsession-client-example](./hello-world-urlsession-client-example) - A CLI client using the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API.
- [hello-world-async-http-client-example](./hello-world-async-http-client-example) - A CLI client using the [AsyncHTTPClient](https://github.com/swift-server/async-http-client) library.
- [hello-world-vapor-server-example](./hello-world-vapor-server-example) - A CLI server using the [Vapor](https://github.com/vapor/vapor) web framework.
- [hello-world-hummingbird-server-example](./hello-world-hummingbird-server-example) - A CLI server using the [Hummingbird](https://github.com/hummingbird-project/hummingbird) web framework.
- [HelloWorldiOSClientAppExample](./HelloWorldiOSClientAppExample) - An iOS client SwiftUI app with a mock server for unit and UI tests.
- [curated-client-library-example](./curated-client-library-example) - A library that hides the generated API and exports a hand-written interface, allowing decoupled versioning.

## Various content types

The following packages show working with various content types, such as JSON, URL-encoded request bodies, plain text, raw bytes, multipart bodies, as well as event streams, such as JSON Lines, JSON Sequence, and Server-sent Events.

- [various-content-types-client-example](./various-content-types-client-example) - A client showing how to provide and handle the various content types.
- [various-content-types-server-example](./various-content-types-server-example) - A server showing how to handle and provide the various content types.
- [event-streams-client-example](./event-streams-client-example) - A client showing how to provide and handle event streams.
- [event-streams-server-example](./event-streams-server-example) - A server showing how to handle and provide event streams.
- [bidirectional-event-streams-client-example](./bidirectional-event-streams-client-example) - A client showing how to provide and handle bidirectional event streams.
- [bidirectional-event-streams-server-example](./bidirectional-event-streams-server-example) - A server showing how to handle and provide bidirectional event streams.

## Integrations

- [swagger-ui-endpoint-example](./swagger-ui-endpoint-example) - A server with endpoints for its raw OpenAPI document and interactive documentation using [Swagger UI](https://github.com/swagger-api/swagger-ui).
- [postgres-database-example](./postgres-database-example) - A server using a [Postgres](https://www.postgresql.org) database for persistent state.
- [command-line-client-example](./command-line-client-example) - A client with a rich command-line interface using [Swift Argument Parser](https://github.com/apple/swift-argument-parser).

## Middleware

- [logging-middleware-oslog-example](./logging-middleware-oslog-example) - A middleware that logs requests and responses using [OSLog](https://developer.apple.com/documentation/os/oslog) (only available on Apple platforms, such as macOS, iOS, and more).
- [logging-middleware-swift-log-example](./logging-middleware-swift-log-example) - A middleware that logs requests and responses using [SwiftLog](https://github.com/apple/swift-log).
- [metrics-middleware-example](./metrics-middleware-example) - A middleware that collects metrics using [SwiftMetrics](https://github.com/apple/swift-metrics).
- [tracing-middleware-example](./tracing-middleware-example) - A middleware that emits traces using [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing).
- [retrying-middleware-example](./retrying-middleware-example) - A middleware that retries some failed requests.
- [auth-client-middleware-example](./auth-client-middleware-example) - A middleware that injects a token header.
- [auth-server-middleware-example](./auth-server-middleware-example) - A middleware that inspects a token header.

## Ahead-of-time (manual) code generation

The recommended way to use Swift OpenAPI generator is by integrating the _build plugin_, which all of the examples above use. The build plugin generates Swift code from your OpenAPI document at build time, and you don't check in the generated code into your git repository. 

However, if you cannot use the build plugin, for example because you must check in your generated code, use the _command plugin_, which you trigger manually either in Xcode or on the command line. See the following example for this workflow:

- [manual-generation-package-plugin-example](./manual-generation-package-plugin-example) - A client using the Swift package command plugin for manual code generation.

If you can't even use the command plugin, for example because your package is not allowed to depend on Swift OpenAPI Generator, you can invoke the generator CLI manually from a Makefile. See the following example for this workflow:

- [manual-generation-generator-cli-example](./manual-generation-generator-cli-example) - A client using the `swift-openapi-generator` CLI for manual code generation.
