# Curated client library

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A library package that shows wrapping a generated client to make a request to the Greeting Service running on `http://localhost:8080`.

The generated code is fully wrapped by the curated, hand-written Swift API. The library doesn't leak the fact that it uses Swift OpenAPI Generator under the hood.

Under the hood, the tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

The server can be started by running any of the Hello World server examples locally.

## Usage

In another package, add this one as a package dependency.

Then, use the provided client API:

```swift
import CuratedLibraryClient

let client = GreetingClient()
let message = try await client.getGreeting(name: "Frank")
print("Received the greeting message: \(message)")
```

## Testing

Run tests using:

```console
% swift test
```

The testing strategy is to use a test implementation of the generated `APIProtocol` that allows simulating various conditions, including errors.

Then, the `GreetingClient` can be exercised in unit tests without it making live network requests under the hood.
