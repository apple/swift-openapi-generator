# Hello World Client

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Overview

A "hello world" command-line tool that uses a generated client to make a request to the Greeting Service running on `http://localhost:8080`.

The tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

The server can be started by running the `HelloWorldServer` example locally.

## Usage

Build and run the client CLI using:

```
$ swift run
Hello, Stranger!
```
