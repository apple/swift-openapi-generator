# Swift OpenAPI Generator

[![](https://img.shields.io/badge/sswg-sandbox-lightgrey.svg)](https://www.swift.org/sswg/)
[![](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation)
[![](https://img.shields.io/github/v/release/apple/swift-openapi-generator)](https://github.com/apple/swift-openapi-generator/releases)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fapple%2Fswift-openapi-generator%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/apple/swift-openapi-generator)

Generate Swift client and server code from an OpenAPI document.

## Overview

[OpenAPI][openapi] is a specification for documenting HTTP services. An OpenAPI document is written in either YAML or JSON, and can be read by tools to help automate workflows, such as generating the necessary code to send and receive HTTP requests.

Swift OpenAPI Generator is a Swift package plugin that can generate the ceremony code required to make API calls, or implement API servers.

The code is generated at build-time, so it's always in sync with the OpenAPI document and doesn't need to be committed to your source repository.

## Features

- Works with OpenAPI Specification versions 3.0 and 3.1.
- Streaming request and response bodies enabling use cases such as JSON event streams, and large payloads without buffering.
- Support for JSON, multipart, URL-encoded form, base64, plain text, and raw bytes, represented as value types with type-safe properties.
- Client, server, and middleware abstractions, decoupling the generated code from the HTTP client library and web framework.

To see these features in action, check out the list of [example projects][examples-generator].

## Usage

Swift OpenAPI Generator can be used to generate API clients and server stubs.

Below you can see some example code, or you can follow one of the [step-by-step tutorials][tutorials-generator].

### Using a generated API client

The generated `Client` type provides a method for each HTTP operation defined in the OpenAPI document[^example-openapi-yaml] and can be used with any HTTP library that provides an implementation of `ClientTransport`.

```swift
import OpenAPIURLSession
import Foundation

let client = Client(
    serverURL: URL(string: "http://localhost:8080/api")!,
    transport: URLSessionTransport()
)
let response = try await client.getGreeting()
print(try response.ok.body.json.message)
```

### Using generated API server stubs

To implement a server, define a type that conforms to the generated `APIProtocol`, providing a method for each HTTP operation defined in the OpenAPI document[^example-openapi-yaml].

The server can be used with any web framework that provides an implementation of `ServerTransport`, which allows you to register your API handlers with the HTTP server.

```swift
import OpenAPIRuntime
import OpenAPIVapor
import Vapor

struct Handler: APIProtocol {
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        let name = input.query.name ?? "Stranger"
        return .ok(.init(body: .json(.init(message: "Hello, \(name)!"))))
    }
}

@main struct HelloWorldVaporServer {
    static func main() async throws {
        let app = Vapor.Application()
        let transport = VaporTransport(routesBuilder: app)
        let handler = Handler()
        try handler.registerHandlers(on: transport, serverURL: URL(string: "/api")!)
        try await app.execute()
    }
}
```

## Package ecosystem

The Swift OpenAPI Generator project is split across multiple repositories to enable extensibility and minimize dependencies in your project.

| Repository                                                 | Description                                        |
| ----------                                                 | -----------                                        |
| [apple/swift-openapi-generator][repo-generator]            | Swift package plugin and CLI                       |
| [apple/swift-openapi-runtime][repo-runtime]                | Runtime library used by the generated code         |
| [apple/swift-openapi-urlsession][repo-urlsession]          | `ClientTransport` using [URLSession][urlsession]   |
| [swift-server/swift-openapi-async-http-client][repo-ahc]   | `ClientTransport` using [AsyncHTTPClient][ahc]     |
| [swift-server/swift-openapi-vapor][repo-vapor]             | `ServerTransport` using [Vapor][vapor]             |
| [swift-server/swift-openapi-hummingbird][repo-hummingbird] | `ServerTransport` using [Hummingbird][hummingbird] |
| [swift-server/swift-openapi-lambda][repo-lambda]           | `ServerTransport` using [AWS Lambda][lambda]       |

## Requirements and supported features

| Generator versions | Supported OpenAPI versions | Minimum Swift version |
| ------------------ | -------------------------- | --------------------- |
| `1.0.0` ... `main` | 3.0, 3.1                   | 5.9                   |

See also [Supported OpenAPI features][supported-openapi-features].

### Supported platforms and minimum versions

The generator is used during development and is supported on macOS and Linux.

The generated code, runtime library, and transports are supported on more
platforms, listed below.

| Component                           | macOS     | Linux | iOS    | tvOS   | watchOS | visionOS |
| ----------------------------------: | :---      | :---  | :-     | :--    | :-----  | :------  |
| Generator plugin and CLI            | ✅ 10.15+ | ✅    | ✖️      | ✖️      | ✖️       | ✖️        |
| Generated code and runtime library  | ✅ 10.15+ | ✅    | ✅ 13+ | ✅ 13+ | ✅ 6+   | ✅ 1+    |

## Documentation and example projects

To get started, check out the [documentation][docs-generator], which contains
[step-by-step tutorials][tutorials-generator].

You can also experiment with [example projects][examples-generator] that use
Swift OpenAPI Generator and integrate with other packages in the ecosystem.

Or if you prefer to watch a video, check out [Meet Swift OpenAPI
Generator](https://developer.apple.com/wwdc23/10171) from WWDC23.

[openapi]: https://openapis.org
[repo-generator]: https://github.com/apple/swift-openapi-generator
[docs-generator]: https://swiftpackageindex.com/apple/swift-openapi-generator/documentation
[tutorials-generator]: https://swiftpackageindex.com/apple/swift-openapi-generator/tutorials/swift-openapi-generator
[supported-openapi-features]: https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/supported-openapi-features
[examples-generator]: https://github.com/apple/swift-openapi-generator/blob/main/Examples/README.md
[repo-runtime]: https://github.com/apple/swift-openapi-runtime
[repo-urlsession]: https://github.com/apple/swift-openapi-urlsession
[urlsession]: https://developer.apple.com/documentation/foundation/urlsession
[repo-ahc]: https://github.com/swift-server/swift-openapi-async-http-client
[ahc]: https://github.com/swift-server/async-http-client
[repo-vapor]: https://github.com/swift-server/swift-openapi-vapor
[vapor]: https://github.com/vapor/vapor
[repo-hummingbird]: https://github.com/swift-server/swift-openapi-hummingbird
[hummingbird]: https://github.com/hummingbird-project/hummingbird
[repo-lambda]: https://github.com/swift-server/swift-openapi-lambda
[lambda]: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
[^example-openapi-yaml]: <details><summary>Example OpenAPI document (click to expand)</summary>

    ```yaml
    openapi: '3.1.0'
    info:
      title: GreetingService
      version: 1.0.0
    servers:
      - url: https://example.com/api
        description: Example service deployment.
    paths:
      /greet:
        get:
          operationId: getGreeting
          parameters:
            - name: name
              required: false
              in: query
              description: The name used in the returned greeting.
              schema:
                type: string
          responses:
            '200':
              description: A success response with a greeting.
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Greeting'
    components:
      schemas:
        Greeting:
          type: object
          description: A value with the greeting contents.
          properties:
            message:
              type: string
              description: The string representation of the greeting.
          required:
            - message
    ```
    </details>
