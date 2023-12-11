# Auth client middleware

In this example we'll implement a `ClientMiddleware` that injects an authentication header into the request.

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example extends the [hello-world-urlsession-client-example](../hello-world-urlsession-client-example)
with a new target, `AuthenticationClientMiddleware`, which is then used when creating
the `Client`.

NOTE: This example shows just one way of injecting authentication information in a middleware
and is purely for illustrative purposes.

The tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

The server can be started by running the `AuthenticationServerMiddleware` example locally.

## Usage

Build and run the client CLI using:

```console
% swift run HelloWorldURLSessionClient token_for_Frank
Hello, Stranger! (Requested by: Frank)
% swift run HelloWorldURLSessionClient invalid_token
Unauthorized
```
