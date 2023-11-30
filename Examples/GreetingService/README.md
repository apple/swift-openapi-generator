# Greeting Service

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Overview

A server that uses generated server stubs to handle requests as the Greeting Service. 

The CLI starts the server on `http://localhost:8080` and can be invoked by the `GreetingServiceClient` example client.

## Usage

Build and run the CLI using:

```
swift run
```

## Testing

Run tests using:

```
swift test
```

The testing strategy is to call the `Handler` directly from tests, as it conforms the `APIProtocol` and implements the business logic.

This allows you to provide any input to the handler methods and verify that the correct outputs are returned, such as error responses when the input data is invalid, and so on.
