# Examples of using Swift OpenAPI Generator

All the examples are self-contained, so you can copy the package directory of your chosen example and use it as a starter template for your project.

## Getting started

Each of the following packages shows an end-to-end working example with the given transport.

- [`HelloWorldURLSessionClient`](./HelloWorldURLSessionClient) - An URLSession-based CLI client.
- [`HelloWorldAsyncHTTPClient`](./HelloWorldAsyncHTTPClient) - An AsyncHTTPClient-based CLI client.
- [`HelloWorldVaporServer`](./HelloWorldVaporServer) - A Vapor-based CLI server
- [`HelloWorldHummingbirdServer`](./HelloWorldHummingbirdServer) - A Hummingbird-based CLI server.

## Content types

The following packages show working with various content types, such as JSON, URL-encoded request bodies, plain text, raw bytes, and multipart bodies.

- [`ContentTypesClient`](./ContentTypesClient) - A client showing how to produce and consume the various content types.
- [`ContentTypesServer`](./ContentTypesServer) - A server showing how to produce and consume the various content types.

## Integrations

- [`SwaggerUIEndpointsServer`](./SwaggerUIEndpointsServer) - a server that vends its OpenAPI document as a raw file and also provides a rendered documentation viewer using swagger-ui.
- [`PostgresDatabaseServer`](./PostgresDatabaseServer) - a server using Postgres for persistent state.

## Middleware

- [`LoggingMiddlewareOSLog`](./LoggingMiddlewareOSLog) - a client middleware that logs requests and responses using OSLog.
- [`LoggingMiddlewareSwiftLog`](./LoggingMiddlewareSwiftLog) - a client and server middleware that logs requests and responses using SwiftLog.
- [`RetryingClientMiddleware`](./RetryingClientMiddleware) - a client middleware that retries failed requests.

## Project and target types

The following examples show various ways that Swift OpenAPI Generator can be adopted from a consumer Swift package or an Xcode project.

- [`CommandLineClient`](./CommandLineClient) - A client showing a Swift Argument Parser-based command line tool Swift package.
- [`iOSAppClient`](./iOSAppClient) - An iOS app client that shows how to make calls to the generated code from SwiftUI and how to perform unit and UI testing with a mock client.
- [`CuratedLibraryClient`](./CuratedLibraryClient) - A client library that completely wraps the generated code and vends a hand-written Swift API, allowing semantic versioning independent of the REST API.

## Generator adoption types

The recommended way to use Swift OpenAPI generator is by integrating the _build plugin_, which all of the examples above use. The build plugin generates Swift code from your OpenAPI document at build time, and you don't check in the generated code into git. 

However, if you cannot use the build plugin, for example because you must check in your generated code, use the _command plugin_, which you trigger manually either in Xcode or on the command line. See the following example for this workflow:

- [`CommandPluginInvocationClient`](./CommandPluginInvocationClient) - A client using the command plugin to regenerate files manually.

If you can't even use the command plugin, for example because your package is not allowed to depend on swift-openapi-generator directly, you can invoke the generator CLI manually from a Makefile. See the following example for this workflow:

- [`ManualGeneratorInvocationClient`](./ManualGeneratorInvocationClient) - A client using the command-line tool to regenerate files manually.

## Deprecated

The following examples will be removed before 1.0.0 is released and is preserved for backwards compatibility with currently published tutorials that point to it.

- [`GreetingService`](./GreetingService) - a Vapor-based CLI server, use `HelloWorldVaporServer` instead
- [`GreetingServiceClient`](./GreetingServiceClient) - a URLSession-based CLI client, use `HelloWorldURLSessionClient` instead
