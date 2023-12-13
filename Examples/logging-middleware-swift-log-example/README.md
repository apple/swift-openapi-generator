# Logging middleware using Swift Log

In this example we'll implement a `ClientMiddleware` and `ServerMiddleware`
that use `swift-log` to log requests and responses.

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example extends the [hello-world-urlsession-client-example](../hello-world-urlsession-client-example)
with a new target, `LoggingMiddleware`, which can be used when creating
a `Client` or a `Server` because it conforms to both the `ClientMiddleware` and
`ServerMiddleware` protocols from the `OpenAPIRuntime` library.

Because request and response bodies support streaming and can be arbitrarily
large, the middleware is configured with a logging policy; one of:

- `never`: Never log request or response bodies.
- `upTo(maxBytes)`: Logs request and response bodies only if they have a known
    length that is less than or equal to `maxBytes`.

For request and response bodies that are unknown length or greater than
`maxBytes`, they are not logged.

NOTE: This example shows just one way of handling HTTP bodies in a middleware
and is purely for illustrative purposes.

It's likely that a fully-featured streaming-aware middleware might employ
a more sophisticated policy, that does not buffer but still logs bodies up to
a certain size, vending its own AsyncSequence to the next middleware in the
chain.

## Testing

By default, the logger will emit logs to standard out. Run the client
executable using:

```console
% swift run
2023-12-07T16:50:35+0000 debug HelloWorldURLSessionClient : body=<none> headers=["Accept=application/json"] method=GET path=/greet [LoggingMiddleware] Request
2023-12-07T16:50:35+0000 debug HelloWorldURLSessionClient : body={
  "message" : "Hello, Stranger!"
} headers=["Connection=keep-alive", "Content-Type=application/json; charset=utf-8", "Date=Thu, 07 Dec 2023 16:50:35 GMT", "Content-Length=36"] method=GET path=/greet [LoggingMiddleware] Response
Hello, Stranger!
```
