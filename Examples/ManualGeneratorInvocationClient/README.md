# A manual generator invocation Client

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Overview

A command-line tool that uses a generated client to make a request to the Greeting Service running on `http://localhost:8080`.

It shows using the Swift OpenAPI Generator command-line tool manually instead of using either the build or command package plugin.

The tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

The server can be started by running the any of the `HelloWorld*Server` examples locally.

## Regenerate code

Whenever the `openapi.yaml` document changes, rerun the code generation:

```
make generate
```

And then check in the changed files in `./Sources/ManualGeneratorInvocationClient/Generated/*`.

## Usage

Build and run the client CLI using:

```
$ swift run
Hello, Stranger!
```
