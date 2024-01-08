# Server supporting event streams

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A server that uses generated server stubs to show how to work with event streams, such as JSON Lines, JSON Sequence, and Server-sent Events.

The tool uses the [Vapor](https://github.com/vapor/vapor) server framework to handle HTTP requests, wrapped in the [Swift OpenAPI Vapor Transport](https://github.com/swift-server/swift-openapi-vapor).

The CLI starts the server on `http://localhost:8080` and can be invoked by running `event-streams-client-example` or on the command line using:

```console
% curl -N http://127.0.0.1:8080/api/greetings\?name\=CLI\&count\=3
{"message":"Hey, CLI!"}
{"message":"Hello, CLI!"}
{"message":"Greetings, CLI!"}
```

## Usage

Build and run the server CLI using:

```console
% swift run
2023-12-01T14:14:35+0100 notice codes.vapor.application : [Vapor] Server starting on http://127.0.0.1:8080
...
```
