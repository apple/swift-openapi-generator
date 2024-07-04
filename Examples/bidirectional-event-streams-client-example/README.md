# Client handling bidirectional event streams

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A command-line tool that uses a generated client to show how to work with bidirectional event streams.

Instead of [URLSession](https://developer.apple.com/documentation/foundation/urlsession), which will return stream only until at least “some” bytes of the body have also been received (see [comment](https://github.com/apple/swift-openapi-urlsession/blob/main/Tests/OpenAPIURLSessionTests/URLSessionBidirectionalStreamingTests/URLSessionBidirectionalStreamingTests.swift#L193-L206)), tool uses the [AsyncHTTPClient](https://github.com/swift-server/async-http-client) API to perform the HTTP call, wrapped in the [AsyncHTTPClient Transport for Swift OpenAPI Generator](https://github.com/swift-server/swift-openapi-async-http-client). A workaround for URLSession could be sending an `empty`, `.joined` or some kind of hearbeat message from server first when initialising a stream.

The server can be started by running `bidirectional-event-streams-server-example` locally.

## Usage

Build and run the client CLI using:

```console
% swift run
Sending and fetching back greetings using JSON Lines
...
```
