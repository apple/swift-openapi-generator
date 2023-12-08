# Hello World server using Hummingbird

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A "hello world" server that uses generated server stubs to handle requests as the Greeting Service. 

The tool uses the [Hummingbird](https://github.com/hummingbird-project/hummingbird) server framework to handle HTTP requests, wrapped in the [Swift OpenAPI Hummingbird Transport](https://github.com/swift-server/swift-openapi-hummingbird).

The CLI starts the server on `http://localhost:8080` and can be invoked by running any of the Hello World example clients or on the command line using:

```
$ curl http://localhost:8080/api/greet
{
  "message" : "Hello, Stranger!"
}
```

## Usage

Build and run the server CLI using:

```
$ swift run
2023-12-01T14:14:35+0100 info HummingBird : [HummingbirdCore] Server started and listening on 127.0.0.1:8080
...
```

## Testing

Run tests using:

```
swift test
```

The testing strategy is to call the `Handler` directly from tests, as it conforms the `APIProtocol` and implements the business logic.

This allows you to provide any input to the handler methods and verify that the correct outputs are returned, such as error responses when the input data is invalid, and so on.

Unit testing of the `Handler` happens without involving any `ServerTransport`, which means that you can change the concrete transport later without changing your tests.
