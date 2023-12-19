# Client handling event streams

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A command-line tool that uses a generated client to show how to work with event streams, such as JSON Lines, JSON Sequence, and Server-sent Events.

The tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

The server can be started by running `event-streams-server-example` locally.

## Usage

Build and run the client CLI using:

```console
% swift run
```
