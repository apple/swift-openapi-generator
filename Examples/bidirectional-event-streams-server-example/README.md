# Server supporting bidirectional event streams

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A server that uses generated server stubs to show how to work with bidirectional event streams.

The tool uses the [Hummingbird](https://github.com/hummingbird-project/hummingbird) server framework to handle HTTP requests, wrapped in the [Swift OpenAPI Hummingbird](https://github.com/swift-server/swift-openapi-hummingbird).

The CLI starts the server on `http://localhost:8080` and can be invoked by running `bidirectional-event-streams-client-example`.

## Usage

Build and run the server CLI using:

```console
% swift run
2024-07-04T08:56:23+0200 info Hummingbird : [HummingbirdCore] Server started and listening on 127.0.0.1:8080
...
```
