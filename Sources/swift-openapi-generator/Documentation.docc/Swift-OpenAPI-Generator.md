# Swift OpenAPI Generator

@Metadata {
    @TechnologyRoot()
}

Generate Swift client and server code from an OpenAPI document.

## Overview

[OpenAPI][openapi] is an open specification for documenting HTTP APIs. An OpenAPI document is written in either YAML or JSON. These machine-readable formats can be read by tools to automate workflows. OpenAPI has an large, existing [ecosystem of tooling][tools].

Swift OpenAPI Generator is a Swift package plugin that can generate the ceremony code required to make API calls, or implement API servers.

The code is generated at build-time, so it's always in sync with the OpenAPI document and doesn't need to be committed to your source repository.

> Tip: In a rush? Take a look at one of our _getting started_ guides: <doc:ClientXcode>, <doc:ClientSwiftPM>, or <doc:ServerSwiftPM>!

### Repository organization

The Swift OpenAPI Generator project is split across multiple repositories to enable extensibility and minimize dependencies in your project.

**swift-openapi-generator** ([source][repo-generator], [docs][docs-generator]) provides the plugin.

**swift-openapi-runtime** ([source][repo-runtime], [docs][docs-runtime]) provides a library with common types and abstractions used by the generated code.

The generated code isn't tied to a specific HTTP client library or web server framework, allowing adopters to use simple input and output data types for API operations. For making and serving HTTP requests, the generated code requires a type that confoms to one of the protocol abstractions, `ClientTransport` or `ServerTransport`, which the user chooses when creating the client or server.

Choose one of the transports listed below, or create your own by adopting the `ClientTransport` or `ServerTransport` protocol:

| Repository | Type | Description |
| ---------- | ---- | ----------- |
| [apple/swift-openapi-urlsession][repo-urlsession] | Client | Uses `URLSession` from [Foundation][foundation]. |
| [swift-server/swift-openapi-async-http-client][repo-ahc] | Client | Uses `HTTPClient` from [AsyncHTTPClient][ahc]. |
| [swift-server/swift-openapi-vapor][repo-vapor] | Server | Uses [Vapor][vapor]. |
| [swift-server/swift-openapi-hummingbird][repo-hummingbird] | Server | Uses [Hummingbird][hummingbird]. |

> Tip: Factor out common logic, for example, for authentication, logging, and retrying, into a _middleware_, by providing a type that adopts `ClientMiddleware` or `ServerMiddleware`. Like transports, middlewares can be used with other projects that use Swift OpenAPI Generator.

### Requirements and supported features

- Swift 5.8
- OpenAPI 3.0.x (for details, see <doc:Supported-OpenAPI-features>)

### Supported platforms and minimum versions

The generator is used during development and is supported on macOS and Linux.

The generated code, runtime library, and transports are supported on more platforms, listed below.

| Component | macOS | Linux | iOS | tvOS | watchOS |
| -: | :-: | :-: | :-: | :-: | :-: |
| Generator plugin and CLI            | ✅ 13+  | ✅     | ❌     | ❌     | ❌    |
| Generated code, runtime, transports | ✅ 13+  | ✅     | ✅ 16+ | ✅ 16+ | ✅ 9+ |

## Topics

### Essentials
- <doc:ClientSwiftPM>
- <doc:ClientXcode>
- <doc:ServerSwiftPM>

### OpenAPI
- <doc:ExploreOpenAPI>
- <doc:Supported-OpenAPI-features>

### Generator plugin and CLI
- <doc:Configuring-the-generator>
- <doc:Manually-invoking-the-generator-CLI>

### API stability
- <doc:API-stability-of-the-generator>
- <doc:API-stability-of-generated-code>

### Getting involved
- <doc:Project-scope-and-goals>
- <doc:Contributing-to-Swift-OpenAPI-Generator>

[openapi]: https://openapis.org
[tools]: https://openapi.tools
[repo-generator]: https://github.com/apple/swift-openapi-generator
[docs-generator]: https://swiftpackageindex.com/apple/swift-openapi-generator/documentation
[repo-runtime]: https://github.com/apple/swift-openapi-runtime
[docs-runtime]: https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation
[repo-urlsession]: https://github.com/apple/swift-openapi-urlsession
[foundation]: https://developer.apple.com/documentation/foundation
[repo-ahc]: https://github.com/swift-server/swift-openapi-async-http-client
[ahc]: https://github.com/swift-server/async-http-client
[repo-vapor]: https://github.com/swift-server/swift-openapi-vapor
[vapor]: https://github.com/vapor/vapor
[repo-hummingbird]: https://github.com/swift-server/swift-openapi-hummingbird
[hummingbird]: https://github.com/hummingbird-project/hummingbird
