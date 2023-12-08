# Tracing middleware using Swift Distributed Tracing

In this example we'll implement a `ClientMiddleware` and `ServerMiddleware`
that use `swift-distributed-tracing` and `swift-otel` to collect and emit
traces for requests and responses.

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example extends the [hello-world-vapor-server-example](../hello-world-vapor-server-example)
with a new target, `TracingMiddleware`, which is then used when creating
the `Server`.

## Testing

### Running the collector and visualization containers

We'll use [Compose](https://docs.docker.com/compose) to run a set of containers
to collect and visualize the traces. In one terminal window, run the following
command:

```console
% docker compose -f docker/docker-compose.yaml up
[+] Running 4/4
 ⠿ Network tracingmiddleware_exporter            Created                            0.1s
 ⠿ Container tracingmiddleware-jaeger-1          Created                            0.3s
 ⠿ Container tracingmiddleware-zipkin-1          Created                            0.4s
 ⠿ Container tracingmiddleware-otel-collector-1  Created                            0.2s
...
```

At this point the tracing collector and visualization tools are running.

### Running the server

Now, in another terminal, run the server locally using the following command:

```console
% swift run
```

### Making some requests

Finally, in a third terminal, make a few requests to the server:

```console
% xargs -n1 -I% curl "localhost:8080/api/greet?name=%" <<< "Juan Mei Tom Bill Anne Ravi Maria"
{
  "message" : "Hello, Juan!"
}
{
  "message" : "Hello, Mei!"
}
{
  "message" : "Hello, Tom!"
}
{
  "message" : "Hello, Bill!"
}
{
  "message" : "Hello, Anne!"
}
{
  "message" : "Hello, Ravi!"
}
{
  "message" : "Hello, Maria!"
}
```

### Visualizing the traces using Jaeger UI

Visit Jaeger UI in your browser at [localhost:16686](http://localhost:16686).

Select `HelloWorldServer` from the dropdown and click `Find Traces`, or use
[this pre-canned link](http://localhost:16686/search?service=HelloWorldServer).

See the traces for the recent requests and click to select a trace for a given request.

Click to expand the trace, the metadata associated with the request and the
process, and the events.

### Visualizing the traces using Zipkin

Now visit Zipkin in your browser at [localhost:9411](http://localhost:9411).

Click to run the empty query and then select a trace.

Similar to Jaeger, you can inspect the trace, the metadata associated with the
request, and the events.
