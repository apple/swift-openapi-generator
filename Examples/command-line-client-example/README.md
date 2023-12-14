# Command-line client

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A command-line tool using Swift Argument Parser that shows using a generated client to make a request to the Greeting Service running on `http://localhost:8080`.

The tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

The server can be started by running any of the Hello World server examples locally.

## Usage

Build and run the client CLI using:

```console
% swift run CommandLineClient greet --name CLI
Hello, CLI!
```
