# A Client without a Transport

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Overview

A library that uses a generated client to make requests to the Greeting Service running on `http://localhost:8080`.

The transport is provided to the library, the library itself doesn't include any transport. 

The library makes two requests to the Greeting Service, printing the returned greetings.

## Usage

Depend on this package from another package:

```
let transport: some ClientTransport = ... // provide a transport in your package
let client = try GreetingServiceClient(transport: transport)
let response = try await client.invoke()
print(response)
```

## Testing

Run tests using:

```
swift test
```

The testing strategy is to implement a mock client transport called `MockTransport`, which returns a canned greeting.

Then the `MockTransport` can be provided to the `GreetingServiceClient` initializer that expects a real transport, conforming to `ClientTransport`.
