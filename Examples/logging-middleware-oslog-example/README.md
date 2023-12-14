# Client logging middleware using OSLog

In this example we'll implement a `ClientMiddleware` that uses `OSLog` to log
requests and responses.

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example extends the
[hello-world-urlsession-client-example](../hello-world-urlsession-client-example)
with a new target, `LoggingMiddleware`, which is then used when creating
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

This example implementation is logging requests and response at debug level
using `com.apple.swift-openapi` as the subsystem. By default, debug logs are
only captured in memory and not persisted unless a configuration change is made
using `log config`. Rather than make a system-wide change, to show this
middleware in action we'll use `log stream` (cf. `log show`). In one terminal,
run the following command (it will not return until you interrupt it using
CTRL-C):

```console
% log stream --debug --info --style compact --predicate subsystem == 'com.apple.swift-openapi'
Filtering the log data using "subsystem == "com.apple.swift-openapi""
```

In another terminal, run the client executable using:

```console
% swift run
Hello, Stranger!
```

You should see in the terminal running `log stream`, that the logs have been
displayed:

```console
% log stream --debug --info --style compact --predicate subsystem == 'com.apple.swift-openapi'
Filtering the log data using "subsystem == "com.apple.swift-openapi""
Timestamp               Ty Process[PID:TID]
2023-12-07 17:09:20.256 Db HelloWorldURLSessionClient[32556:bdad678] [com.apple.swift-openapi:logging-middleware] Request: GET /greet body: <none>
2023-12-07 17:09:20.429 Db HelloWorldURLSessionClient[32556:bdad67a] [com.apple.swift-openapi:logging-middleware] Response: GET /greet 200  body: {
  "message" : "Hello, Stranger!"
}
^C
```
