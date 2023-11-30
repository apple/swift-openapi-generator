# A Service witout a transport

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Overview

A library that uses generated server stubs to handle requests as the Greeting Service. 

The transport is provided to the library, the library itself doesn't include any transport. 

The library handles the Greeting Service routes, returning a canned response.

## Usage

Depend on this package from another package:

```
let transport: some ServerTransport = ... // provide a transport in your package
try GreetingService.register(transport: transport)
// Now send a request to the transport and the response will be produced by GreetingService.
```

## Testing

Run tests using:

```
swift test
```

The testing strategy is to provide a mock `ServerTransport` that returns a mock response.
