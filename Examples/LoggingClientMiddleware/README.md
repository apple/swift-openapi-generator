# Client Logging Middleware using OSLog

In this example we'll implement a `ClientMiddleware` that uses `OSLog` to log
requests and responses.

## Overview

This example extends the [HelloWorldURLSessionClient](../HelloWorldURLSessionClient)
with a new target, `LoggingClientMiddleware`, which is then used when creating
the `Client`.

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

Run the client executable using:

```console
❯ swift run
Hello, Stranger!
```

Check the system logs for logs in the last 5 minutes with the subsystem used
by the middleware:

```console
% log show --last 5m --style compact --debug --info --predicate "subsystem == 'com.apple.swift-openapi'"
Filtering the log data using "subsystem == "com.apple.swift-openapi""
Timestamp               Ty Process[PID:TID]
2023-12-06 20:12:41.758 Db HelloWorldURLSessionClient[63324:baf40a6] [com.apple.swift-openapi:logging-middleware] Request: GET /greet body: <none>
2023-12-06 20:12:41.954 Db HelloWorldURLSessionClient[63324:baf40a9] [com.apple.swift-openapi:logging-middleware] Response: GET /greet 200  body: {
  "message" : "Hello, Stranger!"
}
```
