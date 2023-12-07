# Hello World AsyncHTTPClient Client

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Overview

A "hello world" command-line tool that uses a generated client to make a request to the Greeting Service running on `http://localhost:8080`.

The tool uses the [AsyncHTTPClient](https://github.com/swift-server/async-http-client) API to perform the HTTP call, wrapped in the [Swift OpenAPI AsyncHTTPClient Transport](https://github.com/swift-server/swift-openapi-async-http-client).

The server can be started by running the any of the `HelloWorld*Server` examples locally.

## Usage

Build and run the client CLI using:

```
$ swift run
Hello, Stranger!
```
