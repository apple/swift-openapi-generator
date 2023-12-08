# Swift OpenAPI Generator

[![](https://img.shields.io/badge/sswg-sandbox-lightgrey.svg)](https://www.swift.org/sswg/)
[![](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fapple%2Fswift-openapi-generator%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/apple/swift-openapi-generator)

Generate Swift client and server code from an OpenAPI document.

## Overview

[OpenAPI][openapi] is an open specification for documenting HTTP APIs.

Swift OpenAPI Generator is a Swift package plugin that can generate the ceremony code required to make API calls, or implement API servers.

## Repository organization

The Swift OpenAPI Generator project is split across multiple repositories to enable extensibility and minimize dependencies in your project.

**swift-openapi-generator** ([source][repo-generator], [docs][docs-generator]) provides the plugin.

**swift-openapi-runtime** ([source][repo-runtime], [docs][docs-runtime]) provides a library with common types and abstractions used by the generated code.

> See the generator in action in [Meet Swift OpenAPI Generator](https://developer.apple.com/wwdc23/10171) from WWDC23.

Choose one of the transports listed below, or create your own by adopting the `ClientTransport` or `ServerTransport` protocol:

| Repository | Type | Description |
| ---------- | ---- | ----------- |
| [apple/swift-openapi-urlsession][repo-urlsession] | Client | Uses `URLSession` from [Foundation][foundation]. |
| [swift-server/swift-openapi-async-http-client][repo-ahc] | Client | Uses `HTTPClient` from [AsyncHTTPClient][ahc]. |
| [swift-server/swift-openapi-vapor][repo-vapor] | Server | Uses [Vapor][vapor]. |
| [swift-server/swift-openapi-hummingbird][repo-hummingbird] | Server | Uses [Hummingbird][hummingbird]. |

## Requirements and supported features

| Generator versions | Supported OpenAPI versions | Minimum Swift version |
| -------- | ------- | ----- |
| `1.0.0` ... `main` | 3.0, 3.1 | 5.9 |

### Supported platforms and minimum versions

The generator is used during development and is supported on macOS and Linux.

The generated code, runtime library, and transports are supported on more platforms, listed below.

| Component | macOS | Linux | iOS | tvOS | watchOS | visionOS |
| -: | :-: | :-: | :-: | :-: | :-: | :-: |
| Generator plugin and CLI            | ✅ 10.15+  | ✅     | ❌     | ❌     | ❌    | ❌    |
| Generated code, runtime, transports | ✅ 10.15+  | ✅     | ✅ 13+ | ✅ 13+ | ✅ 6+ | ✅ 1+ |

## Documentation

To get started, check out the full [documentation][docs-generator], which contains step-by-step tutorials!

[openapi]: https://openapis.org
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
