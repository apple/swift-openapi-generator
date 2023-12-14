# Retrying client middleware

In this example we'll implement a `ClientMiddleware` that retries certain failed responses again.

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example extends the [hello-world-urlsession-client-example](../hello-world-urlsession-client-example)
with a new target, `RetryingClientMiddleware`, which is then used when creating
the `Client`.

Requests with a body are only retried if the request body has `iterationPolicy` of `multiple`, as otherwise
the request body cannot be iterated again. 

NOTE: This example shows just one way of retrying HTTP failures in a middleware
and is purely for illustrative purposes.

The tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

The server can be started by running any of the Hello World server examples locally.

## Usage

Build and run the client CLI using:

```
% swift run
Attempt 1
Retrying with code 500
Attempt 2
Returning the received response, either because of success or ran out of attempts.
Hello, Stranger!
```
